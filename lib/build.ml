module type S = sig
  type t

  val build_html : src_dir:string -> dest_dir:string -> t list
end

module Make (C : Collection.S) = struct
  type t = C.t

  let build_html ~src_dir ~dest_dir =
    let fs =
      Files.all_files src_dir
      |> List.filter (fun f -> Filename.extension f = ".md")
    in
    let to_file file =
      match C.v ~file with
      | Ok v ->
          Files.output_html ~doc:(C.to_html v)
            ~path:(dest_dir ^ "/" ^ Filename.chop_extension file ^ ".html");
          v
      | Error (`Msg m) -> failwith ("Failed making: " ^ file ^ " because " ^ m)
    in
    List.map to_file fs
end
