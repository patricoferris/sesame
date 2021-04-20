open Tyxml

let navbar =
  [%html
    {|<nav class="navbar" role="navigation" aria-label="main navigation">
        <div class="navbar-brand">
          <a class="navbar-item" href="/">
            <h1 class="title">OCaml</h1>
          </a>

          <a role="button" class="navbar-burger" aria-label="menu" aria-expanded="false" data-target="navbarBasicExample">
            <span aria-hidden="true"></span>
            <span aria-hidden="true"></span>
            <span aria-hidden="true"></span>
          </a>
        </div>

        <div id="navbarBasicExample" class="navbar-menu">
          <div class="navbar-start">
            <a href="/tutorials" class="navbar-item">
              Tutortials
            </a>
            <hr class="navbar-divider">
            <a href="/changes.html" class="navbar-item">
              Changelog
            </a>
          </div>
        </div>
      </nav>|}]

open Html

let responsive = [ "column"; "is-half-desktop" ]

let title_author_date ~title ~author date =
  [
    h1 [ txt title ];
    p
      ~a:[ a_class [ "author-and-date" ] ]
      [ txt @@ Fmt.str "by %s on %s" author date ];
  ]

let section content =
  section
    ~a:[ a_class [ "section"; "is-medium" ] ]
    [ div ~a:[ a_class [ "container" ] ] content ]

let two_column a b =
  div
    ~a:[ a_class [ "columns"; "is-vcentered" ] ]
    [
      div ~a:[ a_class [ "column"; "is-5"; "is-offset-1" ] ] a;
      div ~a:[ a_class [ "column"; "is-5" ] ] b;
    ]

let hero ?(medium = true) ~title subtitle =
  Html.section
    ~a:
      [
        a_class
          [ "hero"; "is-orange"; (if medium then "is-halfheight" else "") ];
      ]
    [
      div
        ~a:[ a_class [ "hero-body" ] ]
        [
          div
            ~a:
              [
                a_class [ "columns"; "is-centered" ];
                a_style (if medium then "width: 100%" else "");
              ]
            [
              div ~a:[ a_class responsive ]
                [
                  div
                    [
                      h1
                        ~a:[ a_class [ "title"; "has-text-white" ] ]
                        [ txt title ];
                      h1
                        ~a:[ a_class [ "subtitle"; "has-text-white" ] ]
                        [ txt subtitle ];
                    ];
                ];
            ];
        ];
    ]

let simple_head ~t =
  head
    (title (txt t))
    [
      meta ~a:[ a_charset "UTF-8" ] ();
      (* Use https://milligram.io/ because why not *)
      link ~rel:[ `Stylesheet ]
        ~href:"https://cdn.jsdelivr.net/npm/bulma@0.9.2/css/bulma.min.css" ();
      link ~rel:[ `Stylesheet ]
        ~href:
          "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.3/css/all.min.css"
        ();
      link ~rel:[ `Stylesheet ] ~href:"/static/main.css" ();
    ]

type panel_item = {
  link : string;
  icon : string;
  text : Html_types.flow5_without_interactive elt;
}

let panel ~title items =
  nav
    ~a:[ a_class [ "panel" ] ]
    ( [ p ~a:[ a_class [ "panel-heading" ] ] [ txt title ] ]
    @ List.map
        (fun { link; icon; text } ->
          a
            ~a:[ a_class [ "panel-block" ]; a_href link ]
            [
              span
                ~a:[ a_class [ "panel-icon" ] ]
                [
                  i
                    ~a:[ a_class [ "fas"; icon ]; a_aria "hidden" [ "true" ] ]
                    [];
                ];
              text;
            ])
        items )

let centred_section content =
  Html.section
    ~a:[ a_class [ "section" ] ]
    [
      div
        ~a:[ a_class [ "content"; "columns" ] ]
        [ div ~a:[ a_class [ "column"; "is-8"; "is-offset-2" ] ] content ];
    ]

let with_toc toc content =
  div
    ~a:[ a_class [ "content"; "columns"; "is-centered" ] ]
    [
      div ~a:[ a_class responsive ]
        [
          div
            ~a:[ a_class [ "columns" ] ]
            [
              div ~a:[ a_class [ "column"; "is-3" ] ] toc;
              div ~a:[ a_class [ "column"; "is-7"; "is-offset-1" ] ] content;
            ];
        ];
    ]

let html_doc ~head content = html head (body content)
