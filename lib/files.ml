open Core

let all_files root =
  let rec walk acc = function
    | [] -> acc
    | dir :: dirs ->
        let dir_content = Array.to_list (Sys.readdir dir) in
        let added_paths =
          List.rev_map ~f:(fun f -> Filename.concat dir f) dir_content
        in
        let fs =
          List.fold_left ~f:(fun acc f -> f :: acc) ~init:[] added_paths
        in
        let new_dirs = List.filter ~f:(fun f -> Stdlib.Sys.is_directory f) fs in
        walk (fs @ acc) (new_dirs @ dirs)
  in
  walk [] [ root ]

let drop_first_dir ~path =
  String.concat ~sep:"/" (List.tl_exn (String.split ~on:'/' path))

let to_html ~path = Filename.chop_extension path ^ ".html"

let read_file filename =
  let file = In_channel.create filename in
  Exn.protect
    ~f:(fun () -> In_channel.input_all file)
    ~finally:(fun () -> In_channel.close file)

let title_to_dirname s =
  Core.(String.lowercase s |> String.substr_replace_all ~pattern:" " ~with_:"-")

let output_file ~content ~path =
  let outc = Out_channel.create path in
  Exn.protect
    ~f:(fun () -> Out_channel.fprintf outc "%s\n" content)
    ~finally:(fun () -> Out_channel.close outc)

let output_html ~path ~doc =
  let outc = Out_channel.create path in
  let fmt = Format.formatter_of_out_channel outc in
  Exn.protect
    ~f:(fun () -> Format.fprintf fmt "%a@." (Tyxml.Html.pp ~indent:true ()) doc)
    ~finally:(fun () -> Out_channel.close outc)
