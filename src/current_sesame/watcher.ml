let src =
  Logs.Src.create "sesame.watch"
    ~doc:"Current sesame file watcer"

module Log = (val Logs.src_log src : Logs.LOG)

type t = (Fpath.t, string list) Hashtbl.t

let create () = Hashtbl.create 256

let record ~path ~job_id watcher =
  Hashtbl.replace watcher (Fpath.normalize path) job_id

let get_job_id x =
  let open Current.Syntax in
  let+ md = Current.Analysis.metadata x in
  match md with Some { Current.Metadata.job_id; _ } -> job_id | None -> None

let job_id ~path watcher = 
  Hashtbl.find_opt watcher (Fpath.normalize path)

module FS = struct
  open Lwt.Infix

  type t = { 
    f : unit -> unit Lwt.t;
    cond : unit Lwt_condition.t;
    unwatch : unit -> unit Lwt.t;
  }

  let run_job ~watcher ~engine ~dir path =
    let path = Fpath.(v dir // path) in
    Hashtbl.iter (fun k _ -> print_endline (Fpath.to_string k)) watcher;
    let state = Current.Engine.state engine in
    let jobs = state.Current.Engine.jobs in
    match job_id ~path watcher with
    | None -> Log.info (fun f -> f "No job found for %a" Fpath.pp path)
    | Some job_id -> (
        Log.info (fun f -> f "Rebuilding %s because of changes to %a" job_id Fpath.pp path);
        let job = Current.Job.Map.find job_id jobs in
        match job#rebuild with
        | None -> ()
        | Some rebuild -> rebuild () |> ignore )

  let watch ~watcher ~engine dir =
    let events = ref [] in
    let cond = Lwt_condition.create () in
    Irmin_watcher.hook 0 dir (fun e ->
        events := e :: !events;
        Lwt_condition.broadcast cond ();
        Lwt.return_unit)
    >|= fun unwatch ->
    let f () =
      let rec aux () : unit Lwt.t =
        Lwt_condition.wait cond >>= fun () ->
        List.iter (fun p -> run_job ~watcher ~engine ~dir (Fpath.v p)) !events;
        events := [];
        aux ()
      in
      aux ()
    in
    { f; cond; unwatch }
end

module Js = struct
  let script ~port =
    Fmt.str {|<script>
        var socket = new WebSocket('ws://localhost:%i/websocket');

        socket.onopen = function () {
          socket.send("Reload Me Please!");
        };

        socket.onmessage = function (e) {
          window.location.reload()
        }
      </script>
    |} port [@@ocamlformat "disable"]
end
