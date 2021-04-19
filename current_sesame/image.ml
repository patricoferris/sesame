module I = Sesame.Image

module Builder = struct
  type t = Transforms of (I.t -> I.t) list

  let auto_cancel = false

  let id = "current-sesame.images"

  module Key = struct
    type t = I.Transform.conf

    let digest (t : t) =
      Yojson.Safe.to_string
        (`Assoc
          [
            ("quality", `Int t.quality);
            ("dst", `String (Fpath.to_string t.dst));
            ("prefix", `String t.prefix);
            ( "files",
              `List (List.map (fun t -> `String (Fpath.to_string t)) t.files) );
          ])
  end

  module Value = Current.Unit

  let pp ppf t = Fmt.pf ppf "%s" (Key.digest t)

  let build (Transforms ts) job (conf : Key.t) =
    let open Lwt.Infix in
    Current.Job.start job ~level:Current.Level.Harmless >>= fun () ->
    Current.Job.log job "optimising image date %a" pp conf;
    I.Transform.transform ~conf ts |> Lwt_result.return
end

module C = Current_cache.Make (Builder)

let build ?(label = "Procressing Images") ?(ts = []) conf =
  let open Current.Syntax in
  Current.component "%s" label
  |> let> conf = conf in
     C.get (Transforms ts) conf
