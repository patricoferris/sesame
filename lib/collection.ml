open Lwt.Infix
module Jf = Jekyll_format

module type Meta = sig
  type t [@@deriving yaml]
end

module Make (M : Meta) = struct
  type meta = M.t

  module Input = Utils.Fpath_input

  let meta_of_yaml = M.of_yaml

  let meta_to_yaml = M.to_yaml

  type t = { path : string; meta : meta; body : string } [@@deriving yaml]

  module Output = struct
    type nonrec t = t

    let encode t = to_yaml t |> Yaml.to_string_exn

    let decode s = Yaml.of_string_exn s |> of_yaml |> Rresult.R.get_ok

    let pp ppf t = Fmt.pf ppf "%s" (encode t)
  end

  let of_string ~file content =
    match Jf.of_string content with
    | Ok data -> (
        match M.of_yaml Jf.(fields_to_yaml (fields data)) with
        | Ok meta ->
            Ok { path = Fpath.to_string file; meta; body = Jf.body data }
        | Error (`Msg m) -> Error (`Msg m))
    | Error (`Msg m) -> Error (`Msg m)

  let build file =
    Lwt_io.(
      with_file ~mode:input (Fpath.to_string file) @@ fun channel ->
      Lwt_io.read channel >>= fun s -> Lwt.return (of_string ~file s))
end

module Html (M : Meta) = struct
  module C = Make (M)
  module Input = C.Output

  type t = { path : string; html : string } [@@deriving yaml]

  module Output = struct
    type nonrec t = t

    let encode t = to_yaml t |> Yaml.to_string_exn

    let decode s = Yaml.of_string_exn s |> of_yaml |> Rresult.R.get_ok

    let pp ppf t = Fmt.pf ppf "%s" (encode t)
  end

  let build (t : C.t) =
    let body =
      [
        Tyxml.Html.div
          [ Tyxml.Html.Unsafe.data (t.body |> Omd.of_string |> Omd.to_html) ];
      ]
    in
    Components.html ~lang:"en" ~css:"/styles" ~title:"Main"
      ~description:"home page" ~body ()
    |> fun html ->
    { path = t.path; html = Fmt.str "%a" (Tyxml.Html.pp ()) html }
    |> Lwt_result.return
end
