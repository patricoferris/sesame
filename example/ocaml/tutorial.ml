open Tyxml.Html

module Meta = struct
  type user = [ `beginner ] [@@deriving yaml]

  let user_to_string = function `beginner -> "beginner"

  type t = {
    title : string;
    description : string;
    date : string;
    users : user list;
  }
  [@@deriving yaml]
end

module H = struct
  include Sesame.Collection.Html (Meta)

  let build (t : Input.t) =
    let { Meta.title; users; _ } = t.meta in
    let title = h1 [ txt title ] in
    let users =
      div
        ~a:[ a_class [ "user-list" ] ]
        (List.map
           (fun u ->
             span
               ~a:[ a_class [ "tag"; "is-danger" ] ]
               [ txt (Meta.user_to_string u) ])
           users)
    in
    let content =
      body
        [
          Components.navbar;
          section
            ~a:[ a_class [ "section" ] ]
            [
              div
                ~a:[ a_class [ "content"; "columns" ] ]
                [
                  div
                    ~a:[ a_class [ "column"; "is-8"; "is-offset-2" ] ]
                    [
                      div
                        [
                          title;
                          users;
                          Unsafe.data Omd.(to_html (of_string t.body));
                        ];
                    ];
                ];
            ];
        ]
    in
    Components.(html_doc ~head:(simple_head ~t:t.meta.title) content)
    |> Fmt.str "%a" (Tyxml.Html.pp ())
    |> Lwt_result.return
end

module C = Sesame.Collection.Make (Meta)
module Fetch = Current_sesame.Make (C)
module Html = Current_sesame.Make (H)

let build_tutorials ~dst ts =
  let t =
    List.map
      (fun f ->
        let path =
          Current.map
            (fun b ->
              Fpath.(dst // Sesame.Utils.filename_to_html (Fpath.v b.C.A.path)))
            f
        in
        let html = Html.build ~label:"Building Blogposts" f in
        Current_sesame.Local.save path html)
      ts
  in
  t

module Index = struct
  let to_html (ts : C.t Current.t list) =
    let open Current.Syntax in
    Current.component "Index File"
    |> let> ts = Current.list_seq ts in
       let head = Components.simple_head ~t:"Blog Posts" in
       let body =
         body
           [
             Components.navbar;
             Components.section
               [
                 div
                   ~a:[ a_class [ "content"; "columns" ] ]
                   [
                     div
                       ~a:[ a_class [ "column"; "is-8"; "is-offset-2" ] ]
                       [
                         ul
                           (List.map
                              (fun (t : C.t) ->
                                let path =
                                  Fpath.(
                                    v "/" / Conf.tutorial_dir
                                    / Fpath.filename
                                        ( Sesame.Utils.filename_to_html
                                        @@ Fpath.v t.path ))
                                in
                                li
                                  ~a:[ a_style "list-style: none" ]
                                  [
                                    a
                                      ~a:[ a_href (Fpath.to_string path) ]
                                      [
                                        h3 [ txt t.meta.title ];
                                        p [ txt t.meta.description ];
                                      ];
                                  ])
                              ts);
                       ];
                   ];
               ];
           ]
       in
       let html =
         Components.html_doc ~head body |> Fmt.str "%a" (Tyxml.Html.pp ())
       in
       Current_incr.const (Ok html, None)
end
