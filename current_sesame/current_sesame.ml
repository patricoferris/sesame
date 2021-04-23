module Local = Local
module Watcher = Watcher
module Server = Server
module Image = Image

module type Info = sig
  val id : string

  val auto_cancel : bool
end

module SesameInfo = struct
  let id = "sesame"

  let auto_cancel = false
end

module Make_cache (I : Info) (S : Sesame.Types.S) = struct
  type t = No_context

  include I

  module Key = struct
    type t = S.Input.t

    let digest = S.Input.encode
  end

  module Value = struct
    type t = S.Output.t

    let marshal = S.Output.encode

    let unmarshal = S.Output.decode
  end

  let build No_context job f =
    let open Lwt.Infix in
    Current.Job.start job ~level:Current.Level.Harmless >>= fun () ->
    Current.Job.log job "input data %a" S.Input.pp f;
    S.build f

  let pp = S.Input.pp
end

module Cache (S : Sesame.Types.S) =
  Current_cache.Make (Make_cache (SesameInfo) (S))

module Make (V : Sesame.Types.S) = struct
  open Current.Syntax
  module C = Cache (V)

  let build ?(label = "Fetching Data") input =
    Current.component "%s" label
    |> let> input = input in
       C.get No_context input
end

module Make_watch (V : Sesame.Types.S with type Input.t = Fpath.t) = struct
  open Current.Syntax
  module C = Cache (V)

  let build ?watcher ?(label = "Fetching Data") path =
    let build =
      Current.component "%s" label
      |> let> path = path in
         C.get No_context path
    in
    match watcher with
    | None -> build
    | Some watcher ->
        Current.bind
          (function
            | None -> build
            | Some job_id ->
                Current.bind
                  (fun path ->
                    (* Record directory or file *)
                    Watcher.record ~path ~job_id watcher;
                    (* Record contents of directory if it is one *)
                    Bos.OS.Dir.contents path |> function
                    | Ok fs ->
                        List.iter
                          (fun path -> Watcher.record ~path ~job_id watcher)
                          fs;
                        build
                    | _ -> build)
                  path)
          (Watcher.get_job_id build)
end
