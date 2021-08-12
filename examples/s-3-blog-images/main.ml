open Lwt_result.Syntax
open Sesame

module Meta = struct
  type t = {
    title : string;
    author : string;
    description : string;
    date : string;
  }
  [@@deriving yaml]
end

module C = Collection.Make (Meta)
module Cs = Utils.Dir (C)

let out = Fpath.v "out"

module Html = struct
  include Collection.Html (Meta)

  let build (t : C.t) =
    let conf =
      Transformer.Image.v ~quality:50 ~path:(Fpath.v t.path) ~dst:out
        Responsive.Images.(MaxWidth (660, 400, Default 800))
    in
    let omd = Omd.of_string t.body |> Sesame.Transformer.Image.transform conf in
    let body =
      [ Tyxml.Html.div [ Tyxml.Html.Unsafe.data (Omd.to_html omd) ] ]
    in
    Components.html ~title:t.meta.title ~description:t.meta.description ~body ()
    |> fun html ->
    { path = t.path; html = Fmt.str "%a" (Tyxml.Html.pp ()) html }
    |> Lwt_result.return
end

module H = Utils.List (Html)

let main () =
  match Bos.OS.Dir.create out with
  | Error (`Msg m) -> failwith m
  | Ok _ ->
      let* collection = Cs.build (Fpath.v "blog") in
      let* posts = H.build collection in
      Lwt_result.ok
      @@ Lwt_list.iter_p
           (fun ({ path; html } : Html.t) ->
             let path = Fpath.(out // Utils.filename_to_html (v path)) in
             Lwt.return (Result.get_ok (Bos.OS.File.write path html)))
           posts

let () =
  match Lwt_main.run @@ main () with
  | Ok () -> ()
  | Error (`Msg m) -> failwith m
