open Rresult

let all_files root =
  let rec walk acc = function
    | [] -> acc
    | dir :: dirs ->
        let dir_content = Array.to_list (Sys.readdir dir) in
        let added_paths =
          List.rev_map (fun f -> Filename.concat dir f) dir_content
        in
        let fs = List.fold_left (fun acc f -> f :: acc) [] added_paths in
        let new_dirs = List.filter (fun f -> Stdlib.Sys.is_directory f) fs in
        walk (fs @ acc) (new_dirs @ dirs)
  in
  walk [] [ root ]

let list_files ?rel dir =
  Bos.OS.Dir.contents ?rel (Fpath.v dir) |> function
  | Ok lst -> lst
  | Error (`Msg m) -> Fmt.failwith "Listing files in %s failed because %s" dir m

let drop_first_dir ~path =
  String.concat "/" (List.tl (String.split_on_char '/' path))

let to_html ~path = Filename.chop_extension path ^ ".html"

let read_file filename = Bos.OS.File.read (Fpath.v filename)

let title_to_dirname s =
  String.lowercase_ascii s |> String.split_on_char ' ' |> String.concat "-"

let output_file ~path ~content =
  let fpath = Fpath.v path in
  let dir = Fpath.split_base fpath |> fst in
  Bos.OS.Dir.create dir >>= fun _ -> Bos.OS.File.write (Fpath.v path) content

let output_html ~path ~doc =
  let fpath = Fpath.v path in
  let content =
    Tyxml.Html.pp ~indent:true () Format.str_formatter doc;
    Format.flush_str_formatter ()
  in
  let dir = Fpath.split_base fpath |> fst in
  Bos.OS.Dir.create dir >>= fun _ -> output_file ~content ~path

let output_raw ?(body = "") ~path ~yaml () =
  let fpath = Fpath.v path in
  let yaml =
    Yaml.pp Format.str_formatter yaml;
    Format.flush_str_formatter ()
  in
  let dir = Fpath.split_base fpath |> fst in
  Bos.OS.Dir.create dir >>= fun _ ->
  Bos.OS.File.write_lines (Fpath.v path) [ "---"; yaml; "---"; ""; body ]
