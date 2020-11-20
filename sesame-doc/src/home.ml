open Sesame

module Meta = struct
  type t = { title : string; description : string } [@@deriving yaml]
end

module C = struct
  include Collection.Make (Meta)

  let get_title t = t.meta.title

  let build_html (t : t) sidebar =
    let open Tyxml in
    let md = body_md t in
    let body =
      Tyxml.Html.Unsafe.data (md |> Hilite.Md.transform |> Omd.to_html)
    in
    let body = [ sidebar; [%html "<div class='content'>" [ body ] "</div>"] ] in
    Components.html ~lang:"en" ~css:"/styles.css" ~title:t.meta.title
      ~description:t.meta.description ~body
end

module Builder = Build.Make (C)
