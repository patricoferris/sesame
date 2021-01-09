module type S = sig
  type t
  (** The type of buildables *)

  val build_single : path:string -> out:string -> t
  (** Build a single page from a collection -- can be used to generate
      standalone pages *)

  val build_html :
    ?list_files:(string -> string list) ->
    src_dir:string ->
    dest_dir:string ->
    unit ->
    t list
  (** [build src_dir dest_dir] will build a collection that is contained within
      a [src_dir] directory into the [dest_dir] directory as HTML *)
end

(** [Make (C)] is the recommened way of building a collection *)
module Make (C : Collection.S) : S with type t = C.t
