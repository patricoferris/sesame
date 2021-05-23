(* A simple current-sesame pipeline that generate HTML 
   from jekyll-format files and comes complete with hot-reloading *)

module Meta = struct
  type t = { title : string } [@@deriving yaml]
end

(* First some boiler-plate to get the modules we need *)

module C = Sesame.Collection.Make (Meta)
module H = Sesame.Collection.Html (Meta)
module CC = Current_sesame.Make_watch (C)
module HC = Current_sesame.Make(H)

(* Next a file path watcher, this will trigger rebuilds on saves *)

let watcher = Current_sesame.Watcher.create ()

(* ~~~ The pipeline ~~~ *)
let pipeline dst () =
  (* Build a collection and pass in the watcher to record the association *)
  let c =
    CC.build ~watcher ~label:"fetching collection"
      (Fpath.v "data/index.md" |> Current.return)
  in
  (* Build the HTML from the collection using the default build functionality from Sesame *)
  let html = HC.build ~label:"building html" c |> Current.map (fun h -> h.H.A.html) in
  (* Save the HTML string to a file *)
  Current_sesame.Local.save (Fpath.(dst / "index.html") |> Current.return) html

let main dst =
  let dest = Fpath.v dst in
  (* The OCurrent Engine *)
  let engine = Current.Engine.create (pipeline dest) in
  (* Tell the watcher to watch our data directory and get back
     a condition variable that is broadcast to on changes *)
  let f =
    Lwt.map
      (fun (f, cond, _) -> (f, cond))
      (Current_sesame.Watcher.FS.watch ~watcher ~engine "data")
  in
  Lwt_main.run
    (Lwt.choose
       [
         Current.Engine.thread engine;
         Lwt_result.ok
         @@ Lwt.bind f (fun (_, reload) ->
                (* Pass the condition variable into the development server *)
                Current_sesame.Server.dev_server ~port:8080 ~reload dst);
       ])

open Cmdliner

let dst =
  Arg.required
  @@ Arg.pos 0 (Arg.some Arg.file) None
  @@ Arg.info ~doc:"The output directory that should already exist." ~docv:"DST"
       []

let cmd =
  let doc = "Current-sesame Pipeline" in
  (Term.(term_result (const main $ dst)), Term.info "simple pipeline" ~doc)

let () = Term.(exit @@ eval cmd)
