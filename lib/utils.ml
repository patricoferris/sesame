let date_to_ptime = Jekyll_format.parse_date_exn ~and_time:true

let get_time () =
  Ptime.of_float_s (Unix.gettimeofday ()) |> function
  | Some t ->
      Ptime.pp Format.str_formatter t;
      Format.flush_str_formatter ()
  | None -> "2020-09-01 11:15:30 +00:00"

let rec html_path ?(dir = None) path =
  match dir with
  | None -> Fpath.(fst (split_ext path) |> add_ext "html")
  | Some t -> (
      match Fpath.segs path with
      | _ :: rst ->
          html_path ~dir:None
            (List.fold_left (fun acc seg -> Fpath.(acc / seg)) t rst)
      | _ -> failwith "Error")

let filename_to_html path =
  let path = Fpath.filename path |> Fpath.v in
  Fpath.((split_ext path |> fst) + "html")

let title_to_dirname s =
  String.lowercase_ascii s |> String.split_on_char ' ' |> String.concat "-"

module Fpath_input = struct
  type t = Fpath.t

  let encode = Fpath.to_string

  let decode t = Fpath.of_string t |> Rresult.R.get_ok

  let pp = Fpath.pp
end

module Json = struct
  open Lwt.Infix
  module Input = Fpath_input

  type t = Ezjsonm.value

  module Output = struct
    type t = Ezjsonm.value

    let encode t = Ezjsonm.value_to_string t

    let decode s = Ezjsonm.value_from_string s

    let pp ppf t = Fmt.pf ppf "%s" (encode t)
  end

  let build file =
    Lwt_io.(
      with_file ~mode:input (Fpath.to_string file) @@ fun channel ->
      Lwt_io.read channel >>= fun s ->
      Lwt_result.return (Ezjsonm.value_from_string s))
end

module Dir (T : S.S with type Input.t = Fpath.t) = struct
  open Lwt.Infix
  module Input = T.Input

  type t = T.Output.t list

  module Output = struct
    type t = T.Output.t list

    let encode ts =
      Ezjsonm.value_to_string
        (`A (List.map (fun t -> `String (T.Output.encode t)) ts))

    let decode str =
      match Ezjsonm.value_from_string str with
      | `A lst ->
          List.map
            (function
              | `String s -> T.Output.decode s
              | _ -> failwith "Expected strings")
            lst
      | _ -> failwith "Failed to decode value"

    let pp = Fmt.list T.Output.pp
  end

  let build dir =
    let files =
      Bos.OS.Dir.contents dir |> Rresult.R.get_ok
      |> List.filter (fun f -> not (Sys.is_directory @@ Fpath.to_string f))
    in
    Lwt_list.filter_map_p
      (fun file -> T.build file >|= Rresult.R.to_option)
      files
    |> Lwt_result.ok
end

module RecDir (T : S.S with type Input.t = Fpath.t) = struct
  open Lwt.Infix
  include Dir (T)

  let build dir =
    let files =
      Bos.OS.Dir.fold_contents (fun p acc -> p :: acc) [] dir |> Rresult.R.get_ok
      |> List.filter (fun f -> not (Sys.is_directory @@ Fpath.to_string f))
    in
    Lwt_list.filter_map_p
      (fun file -> T.build file >|= Rresult.R.to_option)
      files
    |> Lwt_result.ok
end 

module List (T : S.S) = struct
  open Lwt.Infix

  module Input = struct
    type t = T.Input.t list

    let encode ts =
      Ezjsonm.value_to_string
        (`A (List.map (fun t -> `String (T.Input.encode t)) ts))

    let decode str =
      match Ezjsonm.value_from_string str with
      | `A lst ->
          List.map
            (function
              | `String s -> T.Input.decode s | _ -> failwith "Expected strings")
            lst
      | _ -> failwith "Failed to decode value"

    let pp = Fmt.list T.Input.pp
  end

  type t = T.Output.t list

  module Output = struct
    type t = T.Output.t list

    let encode ts =
      Ezjsonm.value_to_string
        (`A (List.map (fun t -> `String (T.Output.encode t)) ts))

    let decode str =
      match Ezjsonm.value_from_string str with
      | `A lst ->
          List.map
            (function
              | `String s -> T.Output.decode s
              | _ -> failwith "Expected strings")
            lst
      | _ -> failwith "Failed to decode value"

    let pp = Fmt.list T.Output.pp
  end

  let build inputs =
    Lwt_list.filter_map_p
      (fun file -> T.build file >|= Rresult.R.to_option)
      inputs
    |> Lwt_result.ok
end
