open Cmdliner

val build : string -> string -> int
(** [build c d] build from content in [c] to output in [d] *)

val cmd : int Term.t * Term.info
