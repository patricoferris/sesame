(* Simple OCurrent wrapper for Dream.serve *)

module Serve = struct
  type t = Dream.handler

  let auto_cancel = true
  let id = "current-dream.html"

  module Key = Current.Unit

  module Value = Current.Unit

  let build handler job () = 
    let open Lwt.Infix in 
    Current.Job.start job ~level:Current.Level.Harmless >>= fun () ->
    Lwt_result.ok @@ Dream.serve handler
  let pp ppf _ = Fmt.string ppf "Starting dream server"
end

module Raw = struct
  module SC = Current_cache.Make (Serve)

  let serve handler () = SC.get handler ()
end

open Current.Syntax

let serve contents =
  Current.component "dream-serve"
  |> let> contents = contents in
     Raw.serve contents ()