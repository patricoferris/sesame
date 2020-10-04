val all_files : string -> string list
(** [all_files dir] will return all file paths recursively in [dir] *)

val drop_first_dir : path:string -> string
(** [drop_first_dir path] will remove the first directory in path. It raises an
    excpection if after splitting on "/" there is no tail *)

val to_html : path:string -> string
(** [to_html path] will chop the extension from path and add ".html" *)

val read_file : string -> string
(** [read_file filepath] will read the file to a string *)

val title_to_dirname : string -> string
(** [title_to_dirname title] will convert the title to the hyphen-separated
    dirname *)

val output_html : path:string -> doc:Tyxml.Html.doc -> unit
(** [output_html path doc] will print the HTML document [doc] to [path] *)

val output_file : content:string -> path:string -> unit
(** [output_file content path] will dump a [content] to a given [path] *)
