module Images = struct
  type t = MaxWidth of int * int * t | Default of int

  type conf = { root : Fpath.t; conf : Image.Transform.conf }

  let rec get_default_size = function
    | Default i -> i
    | MaxWidth (_, _, xs) -> get_default_size xs

  let rec get_sizes = function
    | Default i -> [ float_of_int i ]
    | MaxWidth (_cond, size, media) -> float_of_int size :: get_sizes media

  let rename_by_size i s = Fmt.str "%s-%i" s i

  let rec get_a_sizes = function
    | Default i -> [ Fmt.str "%ipx" i ]
    | MaxWidth (cond, size, media) ->
        Fmt.str "(max-width: %ipx) %ipx" cond size :: get_a_sizes media

  let sizes_to_srcset f sizes =
    List.map
      (fun s ->
        let s = int_of_float s in
        `Url_width
          (Fpath.(Path.(change_filename f (rename_by_size s) |> to_string)), s))
      sizes

  let resize ~conf sizes =
    let { Image.Transform.quality; rename; files; dst } = conf.conf in
    List.iter
      (fun f ->
        let f = Path.(join_relative ~drop:false conf.root f) in
        let resize size =
          let img =
            try Image.from_file f
            with Images.Wrong_file_type -> failwith (Fpath.to_string f)
          in
          let img = Image.resize size img in
          let rename s = rename s |> rename_by_size (int_of_float size) in
          let output =
            Fpath.(dst // Path.change_filename ~keep_path:false f rename)
          in
          try Image.to_file ~quality img output with
          | Failure fail -> failwith (Fpath.to_string output ^ " " ^ fail)
          | f -> raise f
        in
        List.iter resize sizes)
      files

  let v ~alt ~conf t =
    let open Tyxml.Html in
    let gen_srcset f =
      let sizes = get_sizes t in
      let conf =
        { conf with conf = { conf.conf with Image.Transform.files = [ f ] } }
      in
      resize ~conf sizes;
      let default = get_default_size t in
      let srcset = sizes_to_srcset f sizes in
      ( f,
        img ~alt
          ~src:
            Fpath.(
              Path.(change_filename f (rename_by_size default)) |> to_string)
          ~a:[ a_srcset srcset; a_img_sizes (get_a_sizes t) ]
          () )
    in
    List.map gen_srcset conf.conf.files
end
