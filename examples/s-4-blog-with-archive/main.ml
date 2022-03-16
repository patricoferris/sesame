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

module Html = struct
  include Collection.Html (Meta)

  let build (t : C.t) =
    let body =
      [
        Tyxml.Html.div
          [ Tyxml.Html.Unsafe.data (t.body |> Omd.of_string |> Omd.to_html) ];
      ]
    in
    Components.html ~title:t.meta.title ~description:t.meta.description ~body ()
    |> fun html ->
    { path = t.path; html = Fmt.str "%a" (Tyxml.Html.pp ()) html }
    |> Lwt_result.return
end

module H = Utils.List (Html)

let out = Fpath.v "out"


let main_page collection =
  let module Html = Tyxml.Html in
  let collection =
    List.sort (fun c1 c2 -> compare c1.C.meta.date c2.C.meta.date) collection
  in
  let html_path path = Utils.filename_to_html (Fpath.v path) in
  [
    Html.h1 [Html.txt "Blog Archive"];
    Html.txt "Some posts for you to read";
    Html.ul
      (List.map (fun { C.meta; path; _ } ->
           Html.li [
             Html.h4 [
               Html.a ~a:[Html.a_href (Fpath.to_string (html_path path))]
                 [Html.txt meta.title]
             ];
             Html.txt meta.description;
             Html.br ();
             Html.txt ("Published " ^ meta.date);
           ])
          collection);
  ]

let main () =
  let* collection = Cs.build (Fpath.v "blog") in
  let* posts = H.build collection in
  match Bos.OS.Dir.create out with
  | Error (`Msg m) -> failwith m
  | Ok _ ->
      let* () =
        let path = Fpath.(out / "archive.html") in
        let body = main_page collection in
        let html = Components.html ~title:"Blog Archive"
            ~description:"List of all blog posts" ~body ()
        in
        let html = Fmt.str "%a" (Tyxml.Html.pp ()) html in
        Lwt.return (Bos.OS.File.write path  html)
      in
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
