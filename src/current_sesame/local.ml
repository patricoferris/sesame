open Current.Syntax

let src =
  Logs.Src.create "sesame.fs"
    ~doc:"OCurrent filesystem plugin with Sesame extensions"

module Log = (val Logs.src_log src : Logs.LOG)

let save = Current_fs.save

let save_list ?(create_dirs = false) lst =
  Current.component "save files"
  |> let> paths = lst in
     Current_incr.const
     @@ ( List.map
            (fun (path, value) ->
              match Bos.OS.File.read path with
              | Ok old when old = value ->
                  Log.info (fun f -> f "No change for %a" Fpath.pp path);
                  (Ok (), None)
              | Error _ as e when Bos.OS.File.exists path = Ok true -> (e, None)
              | _ -> (
                  (* Old contents differ, or file doesn't exist. *)
                  if create_dirs then
                    Bos.OS.Dir.create ~path:true (Fpath.parent path) |> ignore
                  else ();
                  match Bos.OS.File.write path value with
                  | Ok () ->
                      Log.info (fun f -> f "Updated %a" Fpath.pp path);
                      (Ok (), None)
                  | Error _ as e -> (e, None)))
            paths
        |> fun _ -> (Ok (), None) )

let read path =
  Current.component "read"
  |> let> path = path in
     Current_incr.const (Bos.OS.File.read path, None)

let read_dir ?filter:_ path =
  let+ path = path in
  let files = Bos.OS.Dir.contents path |> Rresult.R.get_ok in
  List.map
    (fun r -> Bos.OS.File.read r |> fun read -> (r, Rresult.R.get_ok read))
    files

module Copy = struct
  module Builder = struct
    type t = No_context

    let auto_cancel = true

    let id = "copy"

    module Key = struct
      type t = Fpath.t * Fpath.t

      let digest (src, dst) = Fpath.to_string src ^ " " ^ Fpath.to_string dst
    end

    let pp ppf (src, dst) = Fmt.pf ppf "copy %a to %a" Fpath.pp src Fpath.pp dst

    module Value = Current.Unit

    let build No_context job (src, dst) =
      let open Lwt.Infix in
      Current.Job.start job ~level:Current.Level.Harmless >>= fun () ->
      Current.Process.exec ~cancellable:true ~job
        ("", [| "cp"; "-a"; Fpath.to_string src; Fpath.to_string dst |])
  end

  module GC = Current_cache.Make (Builder)
end

let cp ?(label = "") ~src dst =
  let open Current.Syntax in
  Current.component "copy %s" label
  |> let> src = src in
     Copy.GC.get ?schedule:None No_context (src, dst)
