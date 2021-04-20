open Current.Syntax

let watcher = Current_sesame.Watcher.create ()

(* Blog posts *)
let tutorials ~src ~dst =
  Bos.OS.Dir.create dst |> ignore;
  let files = Bos.OS.Dir.contents src |> Rresult.R.get_ok in
  let blogs =
    List.map
      (fun src ->
        ( Fpath.to_string src,
          Tutorial.Fetch.build ~watcher ~label:"Fetching Tutorials"
            (Current.return src) ))
      files
  in
  let index_path = Fpath.(dst / "index.html") |> Current.return in
  let index =
    Tutorial.Index.to_html (List.map snd blogs)
    |> Current_sesame.Local.save index_path
  in
  let builds =
    Tutorial.build_tutorials ~dst (List.map snd blogs)
    |> List.map2 (fun (path, _) x -> (path, x)) blogs
  in
  Current.all_labelled (builds @ [ ("Index", index) ])

(* Generic Pages *)
let pages token =
  let content =
    Page.Fetch.build ~watcher ~label:"Fetching index"
      (Fpath.v "data/index.md" |> Current.return)
  in
  let conf =
    {
      Github.Graphql.token;
      owner = "ocaml";
      repo = "ocaml";
      name = "Patrick Ferris";
      email = "pf341@patricoferris.com";
    }
  in
  let releases =
    Page.Github_releases.build ~label:"Fetching Github Info"
      (Current.return conf)
  in
  let changelog =
    Changes.Changelog.build ~label:"Changelog" (Current.return conf)
    |> Current.map (function `Blob s -> Option.get s)
  in
  let index =
    let* content = content and* releases = releases in
    Page.Build.build ~label:"Building index.html"
      (Page.H.Input.{ releases; content } |> Current.return)
  in
  let changes =
    Changes.Build.build ~label:"Building OCaml Changelog" changelog
  in
  Current.all
    [
      Current_sesame.Local.save
        (Fpath.v "ocaml.org/index.html" |> Current.return)
        index;
      Current_sesame.Local.save
        (Fpath.v "ocaml.org/changes.html" |> Current.return)
        changes;
    ]

(* Copy static assets *)
let copy ~src ~dst =
  Bos.OS.Dir.create dst |> ignore;
  let files =
    Bos.OS.Dir.contents src |> Rresult.R.get_ok
    |> List.filter (fun f -> not (Sys.is_directory @@ Fpath.to_string f))
  in
  let ws =
    List.map
      (fun src ->
        let path = Fpath.(dst / Fpath.filename src) in
        let r = Current_sesame.Local.read (Current.return src) in
        (Fpath.to_string path, Current_sesame.Local.save (Current.return path) r))
      files
  in
  Current.all_labelled ws

let pipeline ~token () =
  Current.all
    [
      tutorials ~src:(Fpath.v "data/tutorials")
        ~dst:Fpath.(v "ocaml.org" / Conf.tutorial_dir);
      pages token;
      copy ~src:(Fpath.v "data/static") ~dst:(Fpath.v "ocaml.org/static");
    ]

let run dev =
  let open Rresult in
  let has_role _ _ = true in
  Bos.OS.Dir.create (Fpath.v "ocaml.org") >>= fun _ ->
  Bos.OS.File.read (Fpath.v ".token") >>= fun token ->
  let engine = Current.Engine.create (pipeline ~token) in
  let f =
    Lwt.map
      (fun (f, cond, _) -> (f, cond))
      (Current_sesame.Watcher.FS.watch ~watcher ~engine "data")
  in
  let routes = Current_web.routes engine in
  let site = Current_web.Site.v ~name:"OCaml.org Builder" ~has_role routes in
  Lwt_main.run
    (Lwt.choose
       ( [
           Current.Engine.thread engine;
           Current_web.run ~mode:(`TCP (`Port 8081)) site;
           Lwt_result.ok @@ Lwt.bind f (fun (f, _) -> f ());
         ]
       @
       if dev then
         [
           Lwt_result.ok
           @@ Lwt.bind f (fun (_, reload) ->
                  Current_sesame.Server.dev_server ~port:8080 ~reload
                    "./ocaml.org");
         ]
       else [] ))

open Cmdliner

let dev = Term.const true

let cmd =
  let module T = Page in
  let doc = "A fake ocaml.org." in
  (Term.(term_result (const run $ dev)), Term.info "ocaml.org" ~doc)

let () = Term.(exit @@ eval cmd)
