module Builder (C : Sesame.Collection.S) : sig
  val build : files:Fpath.t list Current.t -> C.t list Current.t
  (** [build ~file] will generate the collection from a source [file] *)

  val to_html_string : C.t Current.t -> string Current.t
  (** [to_html_string cs] converts the collection [cs] to HTML and then to a
      string ready for saving *)

  val build_index : C.t list Current.t -> string Current.t
  (** [build_index cs] takes a collection [cs] and build the index page for them *)
end
