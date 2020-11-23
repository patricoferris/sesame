open Cmdliner
open Rresult.R.Infix
open Bos.OS
open Config
open Sesame

let build_error = function
  | Ok t -> t
  | Error (`Msg m) -> Fmt.failwith "Build Error: %s" m

let _hd = function [] -> None | x :: _ -> Some x

let is_directory s = Sys.is_directory @@ Fpath.to_string s

let build c_dir d_dir =
  let contents = Dir.contents (Fpath.v c_dir) in
  let sections =
    contents >>| (fun c -> List.filter is_directory c) |> build_error
  in
  let homepage = Home.C.v ~file:(c_dir ^ "/index.md") |> build_error in
  let title = Home.C.get_title homepage in
  let section_values =
    List.map
      (fun section ->
        let path = Fpath.(section / "index.md" |> to_string) in
        Section.C.v ~file:path |> build_error)
      (List.sort Fpath.compare sections)
  in
  let sidebar = Section.C.sidebar ~title section_values in
  Home.C.build_html homepage sidebar |> fun doc ->
  Files.output_html ~path:(d_dir ^ "/index.html") ~doc |> build_error;
  let section_to_dirname s =
    let title = Section.C.get_title s in
    Files.title_to_dirname title
  in
  List.iter
    (fun section ->
      let path =
        Fpath.(v d_dir / section_to_dirname section / "index.html" |> to_string)
      in
      let doc = Section.C.build_html section sidebar in
      Sesame.Files.output_html ~path ~doc |> build_error)
    section_values;
  let build_file dir_path output_path =
    let path = Fpath.((dir_path / "index") + "md") in
    let page = Page.C.v ~file:(Fpath.to_string path) |> build_error in
    let out =
      Fpath.(
        (output_path / Files.title_to_dirname (Page.C.get_title page) / "index")
        + "html")
    in
    let doc = Page.C.build_html page sidebar in
    Sesame.Files.output_html ~path:(change_root c_dir d_dir out) ~doc
  in
  let build section =
    let path = Fpath.(v d_dir / section_to_dirname section) in
    Dir.contents @@ (Fpath.v section.path |> Fpath.split_base |> fst)
    >>= (fun contents ->
          List.filter (fun f -> is_directory f) contents |> fun ds ->
          Ok (List.map (fun d -> build_file d path) ds))
    |> build_error
  in
  let _ = List.map build section_values in
  0

let cmd =
  let doc = "Build your documentation" in
  ( Term.(const build $ Config.content_dir $ Config.dist_dir),
    Term.info "build" ~doc )
