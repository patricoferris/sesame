open Lwt_result.Syntax

module Meta = struct
  type t = { title : string } [@@deriving yaml]
end

module C = Sesame.Collection.Make (Meta)
module H = Sesame.Collection.Html (Meta)

let main () =
  let* collection = C.build (Fpath.v "index.md") in
  let+ build = H.build collection in
  Fmt.(pf stdout "%s" build.html)

let () =
  match Lwt_main.run @@ main () with
  | Ok () -> ()
  | Error (`Msg m) -> failwith m
