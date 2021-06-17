(* Largely copied from the docker base images implementation 
   https://github.com/ocurrent/docker-base-images/blob/master/src/git_repositories.ml *)

open Lwt.Infix
open Current.Syntax

let ( >>!= ) x f = x >>= function Ok y -> f y | Error _ as e -> Lwt.return e

module Builder = struct
  type t = No_context

  let id = "repository"

  module Key = struct
    type t = { name : string; repo : string; branch : string; dest : Fpath.t }

    let digest { name; repo; branch; dest } =
      let json =
        `Assoc
          [
            ("name", `String name);
            ("repo", `String repo);
            ("branch", `String branch);
            ("dest", `String (Fpath.to_string dest));
          ]
      in
      Yojson.Safe.to_string json
  end

  module Value = struct
    type t = { name : string; hash : string; dir : string } [@@deriving yojson]

    let marshal t = to_yojson t |> Yojson.Safe.to_string

    let unmarshal s =
      match Yojson.Safe.from_string s |> of_yojson with
      | Ok x -> x
      | Error _ -> failwith "failed to parse git repository value"
  end

  let get_commit_hash ~job ~repo ~branch dest =
    (* Re-use ocurrent's disk store... maybe not the best idea *)
    let store =
      Fpath.(v (Filename.concat (Sys.getcwd ()) "var") / "sesame-data")
    in
    let data = Fpath.(store // dest) in
    Current.Process.with_tmpdir (fun cwd ->
        Current.Process.exec ~cwd ~cancellable:true ~job
          ("", [| "git"; "clone"; "-b"; branch; repo; "." |])
        >>!= fun () ->
        Current.Process.exec ~cwd ~cancellable:true ~job
          ("", [| "mkdir"; "-p"; Fpath.(to_string store) |])
        >>!= fun () ->
        Current.Process.exec ~cwd ~cancellable:true ~job
          ("", [| "rsync"; "-avq"; "."; Fpath.(to_string data) |])
        >>!= fun () ->
        Current.Process.check_output ~cwd ~cancellable:true ~job
          ("", [| "git"; "rev-parse"; "HEAD" |])
        >>!= fun hash -> Lwt.return (Ok (String.trim hash, data)))

  let build No_context job { Key.name; repo; branch; dest } =
    Current.Job.start job ~level:Current.Level.Mostly_harmless >>= fun () ->
    get_commit_hash ~job ~repo ~branch dest >>!= fun (hash, dir) ->
    Lwt.return (Ok { Value.name; hash; dir = Fpath.to_string dir })

  let pp ppf t = Fmt.pf ppf "Git repo: %s from %s" t.Key.name t.repo

  let auto_cancel = true
end

module Cache = Current_cache.Make (Builder)

type t = { name : string; commit_id : Current_git.Commit_id.t; dir : string }

let v ~name ~repo ~branch dest = Builder.Key.{ name; repo; branch; dest }

let clone ?(gref = "main") ?schedule key =
  let+ { Builder.Value.name; hash; dir } =
    Current.component "Fetching %s" key.Builder.Key.name
    |> let> key = Current.return key in
       Cache.get ?schedule Builder.No_context key
  in
  { name; commit_id = Current_git.Commit_id.v ~repo:key.repo ~gref ~hash; dir }
