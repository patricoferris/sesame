open Sesame

(* A tutorial page's metadata *)
module Meta = struct
  type resource = { author : string; desciption : string; url : string }
  [@@deriving yaml]

  type t = {
    title : string;
    description : string;
    authors : string list;
    date : string;
    resources : resource list;
  }
  [@@deriving yaml]

  let title t = t.title

  let description t = t.description

  let default ~title ~description ~author ~date =
    { title; description; authors = [ author ]; date; resources = [] }
end

module C = struct
  include Collection.Make (Meta)

  let get_title t = t.meta.title

  let build_html (t : t) sidebar =
    let open Tyxml in
    let meta =
      [%html
        "<div class='meta'><h2>" [ Html.txt t.meta.title ] "</h2><p> By "
          [ Html.txt (String.concat " " t.meta.authors) ]
          " on " [ Html.txt t.meta.date ] "</p></div>"]
    in
    let md = body_md t in
    let _access_header_check =
      Checks.check ~exit:false "Headers" Access.well_nested_headers md
    in
    let body = Tyxml.Html.Unsafe.data (body_md t |> Omd.to_html) in
    let body =
      [ sidebar; [%html "<div class='content'>" [ meta; body ] "</div>"] ]
    in
    Components.html ~lang:"en" ~css:"/styles.css" ~title:t.meta.title
      ~description:t.meta.description ~body
end

module Builder = Build.Make (C)
