let change_filename ?(keep_path = true) f rename =
  Fpath.split_base f |> fun (rest, b) ->
  let f =
    Fpath.(v (rename @@ (split_ext b |> fst |> to_string)) + Fpath.get_ext f)
  in
  if keep_path then Fpath.(rest // f) else f

let drop_top_dir path =
  match Fpath.segs path with
  | _ :: rest ->
      List.fold_left (fun f p -> Fpath.add_seg f p) (Fpath.v ".") rest
  | _ -> path
