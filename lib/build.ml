module type S = sig
  type t

  val build_single : path:Fpath.t -> out:string -> t

  val build_html :
    ?list_files:(string -> Fpath.t list) ->
    src_dir:string ->
    dest_dir:string ->
    unit ->
    t list
end

module Make (C : Collection.S) = struct
  type t = C.t

  let build_single ~path ~out =
    match C.v ~file:path with
    | Ok v -> (
        match Files.output_html ~doc:(C.to_html v) ~path:out with
        | Ok () -> v
        | Error (`Msg m) -> failwith m )
    | Error (`Msg m) ->
        failwith ("Failed making: " ^ Fpath.to_string path ^ " because " ^ m)

  let build_html ?list_files ~src_dir ~dest_dir () =
    let fs =
      match list_files with
      | Some f -> f src_dir
      | None ->
          Files.list_files src_dir |> List.map Fpath.to_string
          |> List.filter (fun f -> Filename.extension f = ".md")
          |> List.map Fpath.v
    in
    let to_file file =
      match C.v ~file with
      | Ok v -> (
          let res =
            Files.output_html ~doc:(C.to_html v)
              ~path:
                ( dest_dir ^ "/"
                ^ (Fpath.split_ext file |> fst |> Fpath.to_string)
                ^ ".html" )
          in
          match res with Ok () -> v | Error (`Msg m) -> failwith m )
      | Error (`Msg m) ->
          failwith ("Failed making: " ^ Fpath.to_string file ^ " because " ^ m)
    in
    List.map to_file fs
end
