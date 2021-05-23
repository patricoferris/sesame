let src = Logs.Src.create "irmin-github.github" ~doc:"Github API"

include (val Logs.src_log src : Logs.LOG)
