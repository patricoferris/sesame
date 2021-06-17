open Lwt.Infix [@warning "-32"]

module Date = struct
  type t = Ptime.t

  let of_json_exn json =
    match Ptime.of_rfc3339 (Yojson.Basic.Util.to_string json) with
    | Ok (time, _, _) -> time
    | Error (`RFC3339 (_, err)) -> Fmt.failwith "%a" Ptime.pp_rfc3339_error err

  let parse = of_json_exn

  let serialize t = `String (Ptime.to_rfc3339 t)
end

module Url = struct
  type t = Uri.t

  let parse = function
    | `String s -> Uri.of_string s
    | _ -> Fmt.failwith "Expected a string"

  let serialize t = `String (Uri.to_string t)
end

type 'a res = ('a, [ `Msg of string ]) result

type conf = {
  token : string;
  owner : string;
  repo : string;
  name : string;
  email : string;
}
[@@deriving yojson]

module Make (C : Cohttp_lwt.S.Client) = struct
  let make_headers ~conf =
    [
      ("Content-Type", "application/json");
      ("accept", "application/vnd.github.machine-man-preview+json");
      ("authorization", "Bearer " ^ conf.token);
    ]
    |> Cohttp.Header.of_list

  let run_query ~conf ~parse ~query variables =
    let uri = Uri.of_string "https://api.github.com/graphql" in
    let headers = make_headers ~conf in
    let body = `Assoc [ ("query", `String query); ("variables", variables) ] in
    let body = `String (Yojson.Basic.to_string body) in
    C.post ~headers ~body uri >>= fun (resp, body) ->
    Cohttp_lwt.Body.to_string body >|= fun body ->
    match Cohttp.Code.(code_of_status resp.status |> is_success) with
    | false ->
        Log.err (fun f ->
            f " [ POST ] Status: %i" (Cohttp.Code.code_of_status resp.status));
        Error (`Msg body)
    | true -> (
        try
          Log.info (fun f -> f " [ POST ] Status: 200");
          Yojson.Basic.from_string body
          |> Yojson.Basic.Util.member "data"
          |> parse |> Result.ok
        with
        | Failure err -> Error (`Msg err)
        | Yojson.Json_error err -> Error (`Msg err)
        | Yojson.Basic.Util.Type_error (err, _) -> Error (`Msg err))

  module FileContentQuery = struct
    module Q =
    [%graphql
    {|
      query fileContent($owner: String!, $repo: String!, $file: String!) {
        repository(owner: $owner, name: $repo) {
          file:object(expression: $file) {
            ... on Blob {
              text
            }
          }
        }
      }
    |}]

    let get ~conf ~branch file =
      run_query ~conf ~parse:Q.unsafe_fromJson ~query:Q.query
      @@ (Q.makeVariables ~owner:conf.owner ~repo:conf.repo
            ~file:(Fmt.str "%s:%s" branch file)
            ()
         |> Q.serializeVariables |> Q.variablesToJson)
      >>= function
      | Ok response -> (
          let response = Q.parse response in
          match response.repository with
          | Some repo -> (
              match repo.file with
              | Some (`Blob b) -> Lwt.return (Ok (Some (`Blob b.text)))
              | Some (`UnspecifiedFragment b) ->
                  Lwt.return
                    (Error (`Msg (Fmt.str "Unspecified Fragment %s" b)))
              | None -> Lwt_result.return None)
          | None -> Lwt.return (Ok None))
      | Error e -> Lwt.return (Error e)
  end
  [@warning "-32"]

  module FileQuery = struct
    module Q =
    [%graphql
    {|
    query file($owner: String!, $repo: String!, $file: String!) {
        repository(owner: $owner, name: $repo) {
          file:object(expression: $file) {
            id
          }
        }
      }
    |}]

    let get ~conf ~branch file =
      run_query ~conf ~parse:Q.unsafe_fromJson ~query:Q.query
      @@ (Q.makeVariables ~owner:conf.owner ~repo:conf.repo
            ~file:(Fmt.str "%s:%s" branch file)
            ()
         |> Q.serializeVariables |> Q.variablesToJson)
      >>= function
      | Ok response -> (
          let response = Q.parse response in
          match response.repository with
          | Some repo -> (
              match repo.file with
              | Some s -> Lwt.return (Ok (Some s.id))
              | None -> Lwt_result.return None)
          | None -> Lwt.return (Ok None))
      | Error e -> Lwt.return (Error e)
  end
  [@warning "-32"]

  module FilesQuery = struct
    module Q =
    [%graphql
    {|query repoFiles($owner: String!, $repo: String!) {
      repository(owner: $owner, name: $repo) {
        tree:object(expression: "HEAD:") {
          ... on Tree {
            entries {
              name
            }
          }
        } 
      }
    }|}]

    let get ~conf =
      run_query ~conf ~parse:Q.unsafe_fromJson ~query:Q.query
      @@ (Q.makeVariables ~owner:conf.owner ~repo:conf.repo ()
         |> Q.serializeVariables |> Q.variablesToJson)
      >>= function
      | Ok response -> (
          let response = Q.parse response in
          match response.repository with
          | Some repo -> (
              match repo.tree with
              | Some (`Tree t) -> (
                  match t.entries with
                  | None -> Lwt.return (Ok [||])
                  | Some arr ->
                      Lwt.return
                        (Ok
                           (Array.map
                              (fun t -> { Api.Files.name = t.Q.name })
                              arr)))
              | Some (`UnspecifiedFragment b) ->
                  Lwt.return
                    (Error (`Msg (Fmt.str "Unspecified Fragment %s" b)))
              | None -> Lwt_result.return [||])
          | None -> Lwt.return (Ok [||]))
      | Error e -> Lwt.return (Error e)
  end
  [@warning "-32"]

  module ReleasesQuery = struct
    module Q =
    [%graphql
    {|query releases($owner: String!, $repo: String!) {
    repository(owner: $owner, name: $repo) {
      refs(refPrefix: "refs/tags/", last: 100) {
        nodes {
          repository {
            releases(last: 100, orderBy: { field: CREATED_AT, direction: DESC}) {
              nodes {
                name 
                createdAt @ppxCustom(module: "Date")
                url @ppxCustom(module: "Url")
              }
            }
          }
        }
      }
    }
  }|}]

    let unwrap_array = function Some arr -> arr | None -> [||]

    let get ~conf =
      let ( >>!= ) = Option.bind in
      run_query ~conf ~parse:Q.unsafe_fromJson ~query:Q.query
      @@ (Q.makeVariables ~owner:conf.owner ~repo:conf.repo ()
         |> Q.serializeVariables |> Q.variablesToJson)
      >>= function
      | Ok response ->
          let response = Q.parse response in
          let resp =
            response.repository >>!= fun repo ->
            repo.refs >>!= fun refs ->
            refs.nodes >>!= fun nodes ->
            Some
              (Array.map
                 (fun (x : Q.t_repository_refs_nodes option) ->
                   x >>!= fun x ->
                   x.repository.releases.nodes >>!= fun ts ->
                   Some
                     (Array.map
                        (fun t ->
                          t >>!= fun t ->
                          Some
                            {
                              Api.Release.name = Option.get t.Q.name;
                              created_at = t.createdAt;
                              url = t.url;
                            })
                        ts))
                 nodes)
          in
          Lwt.return (unwrap_array resp |> Array.map unwrap_array)
      | _ -> failwith ""
  end
  [@warning "-32"]

  (* module V3 = struct
       let make_headers ~conf =
         [ ("authorization", Fmt.str "token %s" conf.token) ]
         |> Cohttp.Header.of_list

       let delete ~conf ~uri body =
         let headers = make_headers ~conf in
         C.delete ~headers ~body uri >>= fun (resp, body) ->
         match Cohttp.Code.(code_of_status resp.status |> is_success) with
         | false ->
             Cohttp_lwt.Body.to_string body >>= fun body ->
             Logs.warn (fun f -> f "%s" body);
             Lwt.return @@ Error (`Msg body)
         | true -> Lwt_result.return (Cohttp_lwt.Body.to_string body)

       let get ~conf ~uri body =
         let headers = make_headers ~conf in
         C.put ~headers ~body uri >>= fun (resp, body) ->
         match Cohttp.Code.(code_of_status resp.status |> is_success) with
         | false ->
             Cohttp_lwt.Body.to_string body >>= fun body ->
             Logs.warn (fun f -> f "%s" body);
             Lwt.return @@ Error (`Msg body)
         | true -> Lwt_result.return (Cohttp_lwt.Body.to_string body)

       let put ~conf ~uri body =
         let headers = make_headers ~conf in
         C.put ~headers ~body uri >>= fun (resp, body) ->
         match Cohttp.Code.(code_of_status resp.status |> is_success) with
         | false ->
             Cohttp_lwt.Body.to_string body >>= fun body ->
             Logs.warn (fun f -> f "%s" body);
             Lwt.return @@ Error (`Msg body)
         | true -> Lwt_result.return (Cohttp_lwt.Body.to_string body)

       module Contents = struct
         type committer = { name : string; email : string } [@@deriving yojson]

         type t = {
           path : string;
           message : string;
           committer : committer;
           content : string;
           branch : string;
         }
         [@@deriving yojson]

         let get_sha ~conf path =
           let uri =
             Fmt.str "https://api.github.com/repos/%s/%s/contents/%s" conf.owner
               conf.repo path
             |> Uri.of_string
           in
           let body =
             `Assoc [ ("path", `String path) ]
             |> Yojson.Safe.to_string |> Cohttp_lwt.Body.of_string
           in
           get ~conf ~uri body >>= function
           | Ok response ->
               response >|= fun r ->
               Yojson.Safe.from_string r |> Yojson.Safe.Util.to_assoc
               |> fun assoc -> Ok (List.assoc "sha" assoc |> Yojson.Safe.to_string)
           | Error _ as x -> Lwt.return x

         let remove ~conf ~commit path =
           let uri =
             Fmt.str "https://api.github.com/repos/%s/%s/contents/%s" conf.owner
               conf.repo path
             |> Uri.of_string
           in
           get_sha ~conf path >>= function
           | Ok sha ->
               let body =
                 `Assoc
                   [
                     ( "commit",
                       `Assoc
                         [
                           ("name", `String conf.name);
                           ("email", `String conf.email);
                         ] );
                     ("message", `String commit);
                     ("repo", `String conf.repo);
                     ("sha", `String sha);
                   ]
                 |> Yojson.Safe.to_string |> Cohttp_lwt.Body.of_string
               in
               delete ~conf ~uri body >>= fun _ -> Lwt_result.return ()
           | Error (`Msg m) -> Lwt.return (Error (`Msg m))

         let create ~conf t =
           let t = { t with content = Base64.encode_string t.content } in
           let uri =
             Fmt.str "https://api.github.com/repos/%s/%s/contents/%s" conf.owner
               conf.repo t.path
             |> Uri.of_string
           in
           let body =
             to_yojson t |> Yojson.Safe.to_string |> Cohttp_lwt.Body.of_string
           in
           put ~conf ~uri body
       end
     end *)
end
