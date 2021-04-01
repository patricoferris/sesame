(** {2 Local}

    For performing disk I/O locally like reading files from a directory or
    saving a file somewhere *)

val save : Fpath.t Current.t -> string Current.t -> unit Current.t
(** [save path value] saves [value] to [path] atomically *)

val read : Fpath.t Current.t -> string Current.t
(** [read path] reads the file at [path] and returns a result *)

val read_dir :
  ?filter:'a -> Fpath.t Current.t -> (Fpath.t * string) list Current.t
