(* Simple OCurrent wrapper for Dream.serve *)

module Serve = struct
  type t = {
    interface : string option;
    port : int option;
    stop : unit Lwt.t option;
    debug : bool option;
    error_handler : (Dream.error -> Dream.response option Lwt.t) option;
    secret : string option;
    old_secrets : string list option;
    prefix : string option;
    https : bool option;
    certificate_file : string option;
    key_file : string option;
    builtins : bool option;
    handler : Dream.handler;
  }

  let v ?interface ?port ?stop ?debug ?error_handler ?secret ?old_secrets
      ?prefix ?https ?certificate_file ?key_file ?builtins handler =
    {
      interface;
      port;
      stop;
      debug;
      error_handler;
      secret;
      old_secrets;
      prefix;
      https;
      certificate_file;
      key_file;
      builtins;
      handler;
    }

  let auto_cancel = true

  let id = "current-dream.html"

  module Key = Current.Unit
  module Value = Current.Unit

  let build
      {
        interface;
        port;
        stop;
        debug;
        error_handler;
        secret;
        old_secrets;
        prefix;
        https;
        certificate_file;
        key_file;
        builtins;
        handler;
      } job () =
    let open Lwt.Infix in
    Current.Job.start job ~level:Current.Level.Harmless >>= fun () ->
    Lwt_result.ok
    @@ Dream.serve ?interface ?port ?stop ?debug ?error_handler ?secret
         ?old_secrets ?prefix ?https ?certificate_file ?key_file ?builtins
         handler

  let pp ppf _ = Fmt.string ppf "Starting dream server"
end

module Raw = struct
  module SC = Current_cache.Make (Serve)

  let serve t () = SC.get t ()
end

open Current.Syntax

let serve t =
  Current.component "dream-serve"
  |> let> t = t in
     Raw.serve t ()
