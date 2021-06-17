open Lwt.Infix

let ( / ) = Filename.concat

let inject_script ~port s = s >|= fun s -> s ^ Watcher.Js.script ~port

let static_read ~port file =
  let f s =
    if Filename.extension file = ".html" then inject_script ~port s else s
  in
  Lwt_io.(with_file ~mode:Input file) (fun channel ->
      Lwt_io.read channel |> f |> Lwt.map Dream.response)

let loader ~port dir path _ =
  let file = dir / path in
  Lwt.catch
    (fun () -> static_read ~port file)
    (fun _exn -> Dream.respond ~status:`Not_Found "")

let validate_path path =
  let has_dot = List.exists (( = ) Filename.current_dir_name) path in
  let has_dotdot = List.exists (( = ) Filename.parent_dir_name) path in
  let has_empty = List.exists (( = ) "") path in
  let is_empty = path = [] in
  if has_dot || has_dotdot || has_empty || is_empty then None
  else
    let path = String.concat Filename.dir_sep path in
    if Filename.is_relative path then Some path else None

let static ~port local_root request =
  if not @@ Dream.methods_equal (Dream.method_ request) `GET then
    Dream.respond ~status:`Method_Not_Allowed ""
  else
    let rec aux ?(once = false) path =
      match path with
      | None -> (
          match Dream.path request with
          | [] | [ "/" ] | [ "" ] -> aux ~once:true (Some "index.html")
          | _ -> Dream.respond ~status:`Not_Found "" )
      | Some path -> (
          loader ~port local_root path request >>= fun response ->
          match Dream.status response with
          | `OK ->
              let response =
                if Dream.has_header "Content-Type" response then response
                else
                  Dream.add_header "Content-Type" (Magic_mime.lookup path)
                    response
              in
              Lwt.return response
          | `Not_Found ->
              if once then Lwt.return response
              else
                aux ~once:true
                  (validate_path (Dream.path request @ [ "index.html" ]))
          | _ -> Lwt.return response )
    in
    aux (validate_path (Dream.path request))

let dev_server ~port ~reload dir =
  Dream.serve ~port @@ Dream.logger
  @@ Dream.router
       [
         Dream.get "/websocket" (fun _ ->
             Dream.websocket (fun websocket ->
                 Dream.receive websocket >>= function
                 | Some _ ->
                     Lwt_condition.wait reload >>= fun _ ->
                     Lwt_unix.sleep 0.2 >>= fun _ ->
                     Dream.send websocket "RELOAD" >>= fun () ->
                     Dream.close_websocket websocket
                 | _ -> Dream.close_websocket websocket));
         Dream.get "/**" (static ~port dir);
       ]
  @@ fun _ -> Dream.respond ~status:`Not_Found ""
