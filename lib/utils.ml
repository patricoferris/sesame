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
      | _ -> failwith "Error" )

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
