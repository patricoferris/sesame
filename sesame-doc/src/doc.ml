open Cmdliner

let cmds = [ Builder.cmd; New.cmd ]

let default_cmd =
  let doc = "build nicer long-form documentation with sesame" in
  (Term.(ret (const (`Help (`Pager, None)))), Term.info "sesame-doc" ~doc)

let term_exit x = Term.exit x

let () = term_exit @@ Term.eval_choice default_cmd cmds
