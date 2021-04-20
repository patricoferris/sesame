(** {2 Path Mangling Utilities} *)

val change_filename :
  ?keep_path:bool -> Fpath.t -> (string -> string) -> Fpath.t
(** [change_file path rename] changes the filename of [path]. The optional
    [keep_path] tells the function whether or not to keep the rest of the
    filepath or just return the modified filename *)

val drop_top_dir : Fpath.t -> Fpath.t
(** [drop_top_dir path] removes the top directory from [path], if there is none
    it just returns the path back to you *)

val join_relative : ?drop:bool -> Fpath.t -> Fpath.t -> Fpath.t
(** [join_relative root rel] will join the base of [root] to [rel]. For example
    if I have [a/b/c/index.md] and [../images/hello.jpg] then joining them
    produced [a/b/c/../images/hello.jpg]*)
