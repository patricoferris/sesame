(* Generic Pages *)
open Tyxml.Html

module Meta = struct
  type t = { title : string; description : string; releases : string }
  [@@deriving yaml]
end

(* Github *)

module Github_releases = struct
  open Github
  module Gql = Graphql.Make (Cohttp_lwt_unix.Client)

  module Builder = struct
    type t = No_context

    let id = "github-releases"

    let auto_cancel = false

    module Key = struct
      type t = Graphql.conf

      let digest t = Graphql.conf_to_yojson t |> Yojson.Safe.to_string
    end

    module Value = struct
      type t = Api.Release.t

      let marshal t = Api.Release.to_yojson t |> Yojson.Safe.to_string

      let unmarshal t =
        Yojson.Safe.from_string t |> Api.Release.of_yojson |> Rresult.R.get_ok
    end

    let pp ppf t =
      Yojson.Safe.pp ppf
        (Graphql.conf_to_yojson
           { t with Graphql.token = "HIDING TOKEN FROM LOGS :)" })

    let build No_context job conf =
      let open Lwt.Infix in
      Current.Job.start job ~level:Current.Level.Harmless >>= fun () ->
      Current.Job.log job "github conf %a" pp conf;
      Lwt_result.ok @@ Gql.ReleasesQuery.get ~conf
  end

  module GC = Current_cache.Make (Builder)

  let build ?(label = "Fetching Github Data") conf =
    let open Current.Syntax in
    Current.component "%s" label
    |> let> conf = conf in
       GC.get No_context conf
end

(* HTML *)

module C = Sesame.Collection.Make (Meta)
module Html = Sesame.Collection.Html (Meta)

module H = struct
  module Input = struct
    type t = { releases : Github.Api.Release.t; content : C.t }

    let encode t =
      let json =
        `Assoc
          [
            ("releases", Github.Api.Release.to_yojson t.releases);
            ("content", `String (C.Output.encode t.content));
          ]
      in
      Yojson.Safe.to_string json

    let pp ppf t = Fmt.pf ppf "%s" (encode t)

    let decode s =
      match Yojson.Safe.from_string s with
      | `Assoc [ ("releases", releases); ("content", `String content) ] ->
          {
            releases = Github.Api.Release.of_yojson releases |> Rresult.R.get_ok;
            content = C.Output.decode content;
          }
      | _ -> failwith "Error decoding"
  end

  type t = string

  module Output = Html.Output

  let limit n lst =
    let rec aux m acc t =
      match (m, t) with
      | 0, _ | _, [] -> List.rev acc
      | m, x :: xs -> aux (m - 1) (x :: acc) xs
    in
    aux n [] lst

  let build ({ releases; content } : Input.t) =
    let github_releases =
      Array.map
        (function
          | Some x ->
              [
                Components.
                  {
                    link = Uri.to_string x.Github.Api.Release.url;
                    text =
                      p
                        [
                          txt x.name;
                          txt " ";
                          em
                            ~a:[ a_class [ "has-text-grey" ] ]
                            [
                              txt
                                (Fmt.str "(%a)" (Ptime.pp_human ())
                                   x.created_at);
                            ];
                        ];
                    icon = "fa-box-open";
                  };
              ]
          | None -> [])
        releases.(0)
      |> Array.to_list |> List.concat |> limit 5
    in
    let github_panel =
      Components.panel ~title:"OCaml Releases" github_releases
    in
    let { Meta.title; description; _ } = content.meta in
    let hero = Components.hero ~title description in
    let rels = div [ github_panel ] in
    let content =
      body
        [
          Components.navbar;
          hero;
          Components.(
            section
              [
                two_column
                  [
                    div
                      [ Unsafe.data (Omd.to_html (Omd.of_string content.body)) ];
                  ]
                  [ rels ];
              ]);
        ]
    in
    Components.(html_doc ~head:(simple_head ~t:title) content)
    |> Fmt.str "%a" (Tyxml.Html.pp ())
    |> Lwt_result.return
end

module Fetch = Current_sesame.Make (C)
module Build = Current_sesame.Make (H)
