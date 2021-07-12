module Meta = struct
  type t = { title : string } [@@deriving yaml]
end

module C = Sesame.Collection.Make (Meta)

(* Override the build function with access to the collection's metadata *)
module H = struct
  include Sesame.Collection.Html (Meta)

  let build (t : C.t) =
    let body =
      let open Tyxml.Html in
      [
        h1 [ txt t.meta.title ];
        div [ Unsafe.data (t.body |> Omd.of_string |> Omd.to_html) ];
      ]
    in
    Sesame.Components.html ~lang:"en" ~css:"/styles" ~title:t.meta.title
      ~description:"home page" ~body ()
    |> Fmt.str "%a" (Tyxml.Html.pp ())
    |> Lwt_result.return
end

let build () =
  let open Lwt_result.Syntax in
  let* c = C.build (Fpath.v "data/index.md") in
  let+ html = H.build c in
  Fmt.(pf stdout "%s" html)

let () =
  match Lwt_main.run (build ()) with Ok _ -> () | Error (`Msg m) -> failwith m
