module Jf = Jekyll_format

module type Meta = sig
  type t [@@deriving yaml]
end

module type S = sig
  type meta

  type t = { path : string; meta : meta; body : string }

  val v : file:string -> (t, [> `Msg of string ]) result

  val get_meta : t -> Yaml.value

  val body_string : t -> string

  val body_md : t -> Omd.doc

  val to_html : t -> Tyxml.Html.doc

  val index_html : t list -> Tyxml.Html.doc

  val pp_contents : Format.formatter -> t -> unit
end

module Make (M : Meta) = struct
  type meta = M.t

  type t = { path : string; meta : meta; body : string }

  let get_meta t = M.to_yaml t.meta

  let v ~file =
    let content = Files.read_file file in
    match Jf.of_string content with
    | Ok data -> (
        match M.of_yaml Jf.(fields_to_yaml (fields data)) with
        | Ok meta -> Ok { path = file; meta; body = Jf.body data }
        | Error (`Msg m) -> Error (`Msg m))
    | Error (`Msg m) -> Error (`Msg m)

  let body_string t = t.body

  let body_md t = Omd.of_string t.body

  let to_html (t : t) =
    let body =
      [ Tyxml.Html.div [ Tyxml.Html.Unsafe.data (body_md t |> Omd.to_html) ] ]
    in
    Components.html ~lang:"en" ~css:"/styles" ~title:"Main"
      ~description:"home page" ~body

  let index_html ts =
    let open Tyxml in
    let ts =
      List.map
        (fun t ->
          [%html "<li><a href=" t.path ">" [ Html.txt t.path ] "</a></li>"])
        ts
    in
    let body = [ [%html "<ul>" ts "</ul>"] ] in
    Components.html ~lang:"en" ~css:"/styles" ~title:"Main"
      ~description:"home page" ~body

  let pp_contents ppf t = Format.fprintf ppf "%s" t.body
end
