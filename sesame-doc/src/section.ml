open Sesame
open Tyxml

module Meta = struct
  type page = { title : string; description : string } [@@deriving yaml]

  type t = { title : string; description : string; pages : page list }
  [@@deriving yaml]

  let make ~title ~description = { title; description; pages = [] }

  let make_page ~title ~description = { title; description }

  let get_pages t = t.pages

  let add_page t p = { t with pages = t.pages @ [ p ] }
end

let section_page_of_page p =
  Meta.{ title = Page.Meta.title p; description = Page.Meta.description p }

module C = struct
  include Collection.Make (Meta)

  let get_title t = t.meta.title

  let add_page t p = { t with meta = Meta.add_page t.meta p }

  let handle_error = function
    | Ok t -> t
    | Error (`Msg m) -> Fmt.failwith "%s" m

  let sidebar ~title (sections : t list) =
    let mk_link title path =
      [%html "<li><a href=" path ">" [ Html.txt title ] "</a></li>"]
    in
    let f (s : t) =
      let meta = get_meta s |> Meta.of_yaml |> handle_error in
      let pages =
        meta.pages
        |> List.map (fun (p : Meta.page) ->
               let path =
                 Fpath.(
                   v "/"
                   / Files.title_to_dirname (get_title s)
                   / Files.title_to_dirname p.title)
               in
               mk_link p.title (Fpath.to_string path))
      in
      [%html
        "<li><a href="
          Fpath.(v "/" / Sesame.Files.title_to_dirname meta.title |> to_string)
          ">" [ Html.txt meta.title ] "</a><ul>" pages "</ul></li>"]
    in
    List.map f sections |> fun x ->
    [%html
      "<div class='nav'><h1 class='title'><a href='/'>" [ Html.txt title ]
        "</a></h1><ul>" x "</ul></div>"]

  let build_html t sidebar =
    let open Tyxml in
    let meta =
      [%html "<div class='meta'><h2>" [ Html.txt t.meta.title ] "</h2></div>"]
    in
    let md = body_md t in
    (* let _access_header_check =
         Checks.check ~exit:false "Headers for \n" Access.well_nested_headers md
       in *)
    let body =
      Tyxml.Html.Unsafe.data (md |> Hilite.Md.transform |> Omd.to_html)
    in
    let body =
      [ sidebar; [%html "<div class='content'>" [ meta; body ] "</div>"] ]
    in
    Components.html ~lang:"en" ~css:"/styles.css" ~title:t.meta.title
      ~description:"Sesame: simple static site generator" ~body
end

module Builder = Build.Make (C)
