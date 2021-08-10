val date_to_ptime : string -> Ptime.t
(** [date_to_ptime s] converts the string [s] to a [Ptime.t] *)

val get_time : unit -> string
(** [get_time ()] gets the current time... might be removed because it is a UNIX
    only thing *)

val html_path : ?dir:Fpath.t option -> Fpath.t -> Fpath.t
(** [html_path ?dir path] turns [a/b/c.md] into [a/b/c.html] *)

val filename_to_html : Fpath.t -> Fpath.t

val title_to_dirname : string -> string

module Fpath_input : S.Encodeable with type t = Fpath.t
(** A useful {!S.Encodeable} compliant module [Fpath.t] *)

(** A {!S.S} compliant module for JSON (using [Ezjson.value]) *)
module Json : S.S with type Input.t = Fpath.t and type t = Ezjsonm.value

(** Build a module that will build things from a directory of files *)
module Dir (T : S.S with type Input.t = Fpath.t) :
  S.S with type Input.t = Fpath.t and type t = T.Output.t list

(** Same as {!Dir} except will recursively search the directory for files*)
module RecDir (T : S.S with type Input.t = Fpath.t) :
  S.S with type Input.t = Fpath.t and type t = T.Output.t list

module List (T : S.S) :
  S.S with type Input.t = T.Input.t list and type t = T.Output.t list
