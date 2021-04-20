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

  module A = struct
    type t = { path : string; meta : meta; body : string } [@@deriving yaml]
  end

  type t = A.t

  module Output = struct
    type t = A.t

    let encode t = A.to_yaml t |> Yaml.to_string_exn

    let decode s = Yaml.of_string_exn s |> A.of_yaml |> Rresult.R.get_ok

    let pp ppf t = Fmt.pf ppf "%s" (encode t)
  end

  let of_string ~file content =
    match Jf.of_string content with
    | Ok data -> (
        match M.of_yaml Jf.(fields_to_yaml (fields data)) with
        | Ok meta ->
            Ok { A.path = Fpath.to_string file; meta; body = Jf.body data }
        | Error (`Msg m) -> Error (`Msg m) )
    | Error (`Msg m) -> Error (`Msg m)

  let build file =
    Lwt_io.(
      with_file ~mode:input (Fpath.to_string file) @@ fun channel ->
      Lwt_io.read channel >>= fun s -> Lwt.return (of_string ~file s))
end

module Html (M : Meta) = struct
  module C = Make (M)
  module Input = C.Output

  type t = string

  module Output = struct
    type t = string

    let encode (t : t) = Fun.id t

    let decode (t : t) = Fun.id t

    let pp ppf = Fmt.pf ppf "%s"
  end

  let build (t : C.t) =
    let body =
      [
        Tyxml.Html.div
          [ Tyxml.Html.Unsafe.data (t.body |> Omd.of_string |> Omd.to_html) ];
      ]
    in
    Components.html ~lang:"en" ~css:"/styles" ~title:"Main"
      ~description:"home page" ~body
    |> Fmt.str "%a" (Tyxml.Html.pp ())
    |> Lwt_result.return
end

module type Transformer = sig
  type t

  val transform : t -> (t, [ `Msg of string ]) Lwt_result.t
end
