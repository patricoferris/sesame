open Sesame

module Blog_meta = struct
  type t = {
    title : string;
    description : string;
    date : string;
    author : string;
    tags : string list;
    image : string;
    credit : string option;
  }
  [@@deriving yaml]
end

module Blog_collection = struct
  include Collection.Make (Blog_meta)

  let to_html (t : t) =
    let open Tyxml in
    let img =
      [%html
        "<img class='hero' alt='Image of something' src='"
          ("../images/modified-" ^ Filename.basename t.meta.image)
          "' />"]
    in
    let img_credit =
      match t.meta.credit with
      | Some credit -> [ [%html "<p>" [ Html.txt credit ] "</p>"] ]
      | _ -> []
    in
    let meta =
      [%html
        "<div class='meta'><h2>" [ Html.txt t.meta.title ] "</h2><p> By "
          [ Html.txt t.meta.author ] " on " [ Html.txt t.meta.date ]
          "</p></div>"]
    in
    let body = Tyxml.Html.Unsafe.data (body_md t |> Omd.to_html) in
    let body =
      [
        Comps.navbar;
        [%html
          "<div class='content'>"
            ([ meta; img ] @ img_credit @ [ body ])
            "</div>"];
      ]
    in
    Components.html ~lang:"en" ~title:t.meta.title ~description:"" ~body

  let index_html ts =
    let open Tyxml in
    let time t = Utils.date_to_ptime t.meta.date in
    let ts =
      List.sort (fun t1 t2 -> -Ptime.compare (time t1) (time t2)) ts
      |> List.map (fun t ->
             print_endline t.path;
             [%html
               "<li><h3><a href="
                 ("/" ^ Files.to_html ~path:t.path)
                 ">" [ Html.txt t.meta.title ] "</a></h3><p>"
                 [ Html.txt t.meta.description ]
                 "...</p></li>"])
    in
    let body =
      [ Comps.navbar; [%html "<div class='content'><ul>" ts "</ul></div>"] ]
    in
    Components.html ~lang:"en" ~title:"Blog" ~description:"Blog index page"
      ~body
end

module Blog_builder = Build.Make (Blog_collection)

let () =
  Blog_builder.build_html ~src_dir:"blogs" ~dest_dir:"." |> fun ts ->
  Files.output_html ~path:"blogs/index.html"
    ~doc:(Blog_collection.index_html ts);
  Image.transform ~quality:60 ~src:"images" ~ext:".jpg" ~dst:"images"
    [ Image.resize 1000.; Image.mono ]
