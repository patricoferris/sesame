(* Changelog *)
open Tyxml.Html

(* Processing *)

let transform doc =
  let check_last_char s len =
    match String.sub s (len - 1) 1 with
    | ":" -> (true, ":")
    | ")" -> (true, ")")
    | "," -> (true, ",")
    | _ -> (false, "")
  in
  let replace_prs body =
    String.split_on_char ' ' body
    |> List.map (fun s ->
           let len = String.length s in
           if len > 2 && String.sub s 0 1 = "#" then
             match int_of_string_opt (String.sub s 1 (len - 1)) with
             | Some pr ->
                 Fmt.str "[%s](https://github.com/ocaml/ocaml/pull/%i)" s pr
             | None ->
                 let b, c = check_last_char s len in
                 if b then
                   match int_of_string_opt (String.sub s 1 (len - 2)) with
                   | Some pr ->
                       Fmt.str "[%s](https://github.com/ocaml/ocaml/pull/%i)%s"
                         (String.sub s 0 (len - 2))
                         pr c
                   | None -> s
                 else s
           else s)
    |> String.concat " "
  in
  replace_prs doc

module Changelog = struct
  open Github
  module Gql = Graphql.Make (Cohttp_lwt_unix.Client)

  module Builder = struct
    type t = No_context

    let id = "github-changes"

    let auto_cancel = false

    module Key = struct
      type t = Graphql.conf

      let digest t = Graphql.conf_to_yojson t |> Yojson.Safe.to_string
    end

    module Value = struct
      type t = Api.FileContents.t

      let marshal t = Api.FileContents.to_yojson t |> Yojson.Safe.to_string

      let unmarshal t =
        Yojson.Safe.from_string t |> Api.FileContents.of_yojson
        |> Rresult.R.get_ok
    end

    let pp ppf t =
      Yojson.Safe.pp ppf
        (Graphql.conf_to_yojson
           { t with Graphql.token = "HIDING TOKEN FROM LOGS :)" })

    let build No_context job conf =
      let open Lwt.Infix in
      Current.Job.start job ~level:Current.Level.Harmless >>= fun () ->
      Current.Job.log job "github conf %a" pp conf;
      Lwt_result.map
        (fun t -> Option.get t)
        (Gql.FileContentQuery.get ~conf ~branch:"trunk" "Changes")
  end

  module GC = Current_cache.Make (Builder)

  let build ?(label = "Fetching Github Data") conf =
    let open Current.Syntax in
    Current.component "%s" label
    |> let> conf = conf in
       GC.get No_context conf
end

(* HTML *)

module String = struct
  type t = string

  let encode = Fun.id

  let decode = Fun.id

  let pp ppf = Fmt.pf ppf "%s"
end

module H = struct
  module Input = String

  type t = string

  module Output = String

  let build (s : Input.t) =
    let omd =
      Omd.of_string @@ transform s |> Sesame.Transformer.Toc.transform
    in
    let toc = Sesame.Transformer.Toc.(toc omd |> to_tree |> preorder) in
    let content =
      [
        Components.navbar;
        Components.with_toc [ toc ] [ Unsafe.data @@ Omd.to_html omd ];
      ]
    in
    Components.(html_doc ~head:(simple_head ~t:"Changelog") content)
    |> Fmt.str "%a" (Tyxml.Html.pp ())
    |> Lwt_result.return
end

module Build = Current_sesame.Make (H)
