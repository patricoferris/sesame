let change_filename ?(keep_path = true) f rename =
  Fpath.split_base f |> fun (rest, b) ->
  let f =
    Fpath.(v (rename @@ (split_ext b |> fst |> to_string)) + Fpath.get_ext f)
  in
  if keep_path then Fpath.(rest // f) else f

let drop_top_dir path =
  let rec aux = function
    | "." :: rest -> aux rest
    | _ :: rest ->
        List.fold_left (fun f p -> Fpath.add_seg f p) (Fpath.v ".") rest
    | _ -> path
  in
  aux (Fpath.segs path)

let join_relative ?(drop = true) md_path img_path =
  if Fpath.is_abs img_path then
    failwith "Only relative image paths are supported in markdown file for now"
  else
    Fpath.split_base (if drop then drop_top_dir md_path else md_path) |> fst
    |> fun b -> Fpath.(b // img_path)
