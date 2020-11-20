open Cmdliner

val content_dir : string Term.t

val dist_dir : string Term.t

val section : string -> string

val change_root : string -> string -> Fpath.t -> string

val remove_root : string -> Fpath.t -> string
