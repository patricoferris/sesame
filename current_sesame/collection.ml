open Current.Syntax
open Lwt.Infix

(** {2 Sesame Transformations} *)

type ctx = No_context

module Build (C : Sesame.Collection.S) = struct
  type t = ctx

  let id = "sesame-build"

  let auto_cancel = false

  module Key = struct
    type t = Fpath.t list

    let digest t = Fmt.str "%a" Fmt.(list Fpath.pp) t
  end

  module Value = struct
    type t = C.t list

    let marshal ts = `A (List.map C.to_yaml ts) |> Yaml.to_string_exn

    let unmarshal s =
      Yaml.of_string_exn s |> function
      | `A lst -> List.map (fun t -> C.of_yaml t |> Rresult.R.get_ok) lst
      | _ -> failwith "Expected list of values"
  end

  let build No_context job files =
    Current.Job.start job ~level:Current.Level.Harmless >>= fun () ->
    let c file =
      let c = C.v ~file in
      ( match c with
      | Ok t -> Current.Job.log job "Successfully built %s" t.path
      | Error (`Msg m) -> Current.Job.log job "Unsuccessfully built [Err: %s]" m
      );
      c |> Rresult.R.get_ok
    in
    Lwt_result.return (List.map c files)

  let pp ppf t =
    Fmt.pf ppf "sesame-build [%a]" (Fmt.list ~sep:Fmt.comma Fpath.pp) t
end

module Builder (C : Sesame.Collection.S) = struct
  module BC = Current_cache.Make (Build (C))

  let build ~files =
    Current.component "Building Collection"
    |> let> files = files in
       BC.get No_context files

  let doc_to_string doc = Fmt.str "%a" (Tyxml_html.pp ()) doc

  let to_html_string c = Current.map (fun c -> C.to_html c |> doc_to_string) c

  let build_index cs =
    Current.component "Building Index Page"
    |> let> cs = cs in
       Current_incr.const (Ok (C.index_html cs |> doc_to_string), None)
end
