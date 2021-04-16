open Lwt.Infix

let default_loader local_root path _ =
  let file = Filename.concat local_root path in
  Lwt.catch
    (fun () ->
      Lwt_io.(with_file ~mode:Input file) (fun channel ->
          Lwt_io.read channel |> Lwt.map Dream.response))
    (fun _exn -> Dream.respond ~status:`Not_Found "")

let inject_script ~port s = s >|= fun s -> s ^ Watcher.Js.script ~port

let loader ~port dir path x =
  match Filename.extension path with
  | ".html" ->
      let file = Filename.concat dir path in
      Lwt.catch
        (fun () ->
          Lwt_io.(with_file ~mode:Input file) (fun channel ->
              Lwt_io.read channel |> inject_script ~port
              |> Lwt.map Dream.response))
        (fun _exn -> Dream.respond ~status:`Not_Found "")
  | _ -> default_loader dir path x

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
                     Dream.send "RELOAD" websocket >>= fun () ->
                     Dream.close_websocket websocket
                 | _ -> Dream.close_websocket websocket));
         Dream.get "*" (Dream.static ~loader:(loader ~port) dir);
       ]
  @@ Dream.not_found
