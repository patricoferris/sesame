open Rresult
open Sesame

type typ = Section | Page

let typ_of_string s =
  match String.lowercase_ascii s with
  | "section" -> Section
  | "page" -> Page
  | _ -> Fmt.failwith "I can't build a %s" s

let ask ?(break = false) question default =
  (if break then Format.(fprintf std_formatter "%s\n%!" question)
  else Format.(fprintf std_formatter "%s: %!" question));
  let line = read_line () in
  match (line, default) with "", d -> Ok d | l, _ -> Ok l

let new_section c_dir =
  ask "Title of the section" "Default Title" >>= fun title ->
  ask "Short description of the section" "Default Description"
  >>= fun description ->
  ask "Number of section (e.g. 1, 10...)" "1" >>= fun i ->
  let meta = Section.Meta.make ~title ~description in
  let path = Fpath.(v c_dir / Config.section i / "index.md" |> to_string) in
  Files.output_raw ~path ~yaml:(Section.Meta.to_yaml meta) ()

let new_page content_dir =
  ask "Title of the new page" "Default title" >>= fun title ->
  ask "Description of the new page" "Default description" >>= fun description ->
  ask "Who is the author" "Alice" >>= fun author ->
  ask "What section does it belong to? (e.g. 1, 10...)" "1" >>= fun s ->
  let sec = Config.section s in
  let section_page = Section.Meta.make_page ~title ~description in
  let section_path = Fpath.(v content_dir / sec / "index.md" |> to_string) in
  let path =
    content_dir ^ "/" ^ sec ^ "/" ^ Files.title_to_dirname title ^ "/index.md"
  in
  Section.C.v ~file:section_path >>= fun section ->
  let section = Section.C.add_page section section_page in
  Files.output_raw ~path:section_path
    ~body:(Section.C.body_string section)
    ~yaml:(Section.C.get_meta section)
    ()
  >>= fun () ->
  let meta =
    Page.Meta.default ~title ~description ~author
      ~date:(Sesame.Utils.get_time ())
  in
  Files.output_raw ~path ~yaml:(Page.Meta.to_yaml meta) ()

let handle_error = function
  | Ok t -> t
  | Error (`Msg m) -> Fmt.failwith "Build a new part of the site failed :( %s" m

let new_cmd typ c_dir =
  match typ_of_string typ with
  | Section ->
      new_section c_dir |> handle_error;
      0
  | Page ->
      new_page c_dir |> handle_error;
      0

open Cmdliner

let typ =
  Arg.required
  @@ Arg.pos 0 Arg.(some string) None
  @@ Arg.info ~doc:"What are you building - a `section' or a `page'"
       ~docv:"SECTION" []

let cmd =
  let doc = "A new a new section or page to your exisiting documentation" in
  (Term.(const new_cmd $ typ $ Config.content_dir), Term.info "new" ~doc)
