open Sesame

(* A tutorial page's metadata *)
module Meta = struct
  type resource = { title : string; description : string; url : string }
  [@@deriving yaml]

  type t = {
    title : string;
    description : string;
    authors : string list;
    date : string;
    toc : bool;
    resources : resource list;
  }
  [@@deriving yaml]

  let title t = t.title

  let description t = t.description

  let toc t = t.toc

  let default ~title ~description ~author ~date =
    {
      title;
      description;
      authors = [ author ];
      date;
      resources = [];
      toc = false;
    }
end

module C = struct
  include Collection.Make (Meta)

  let get_title t = t.meta.title

  let build_html (t : t) sidebar =
    let open Tyxml in
    let make_resources lst =
      let to_elt (e : Meta.resource) =
        [%html
          "<li><a href=" e.url ">" [ Html.txt e.title ] "</a> - "
            [ Html.txt e.description ] "</li>"]
      in
      [%html
        {|
        <ol>
          |}
          (List.map to_elt lst)
          {|
        </ol>
      |}]
    in
    let meta =
      [%html
        "<div class='meta'><h2>" [ Html.txt t.meta.title ] "</h2><p> By "
          [ Html.txt (String.concat " " t.meta.authors) ]
          " on " [ Html.txt t.meta.date ] "</p></div>"]
    in
    let md = body_md t in
    let toc =
      if t.meta.toc then
        let t = Transformer.Toc.toc md in
        [ Transformer.Toc.to_html t ]
      else []
    in
    let body =
      Tyxml.Html.Unsafe.data
        (md |> Hilite.Md.transform |> Transformer.Toc.transform |> Omd.to_html)
    in
    let body =
      [
        sidebar;
        [%html
          "<div class='content'>"
            ([ meta ] @ toc @ [ body; make_resources t.meta.resources ])
            "</div>"];
      ]
    in
    Components.html ~lang:"en" ~css:"/styles.css" ~title:t.meta.title
      ~description:t.meta.description ~body
end

module Builder = Build.Make (C)
