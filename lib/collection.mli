module type Meta = sig
  type t [@@deriving yaml]
  (** The type to describe your front-matter - this will most likely be a record *)
end

module type S = sig
  type meta

  type t = { path : string; meta : meta; body : string }
  (** The type of documents within a collection *)

  val v : file:string -> (t, [> `Msg of string ]) result
  (** [v file] will convert a markdown file to a [t] using the function provided
      by the [Meta] module. If it fails during this process it will return an
      [Error (`Msg m)]. *)

  val get_meta : t -> Yaml.value
  (** [meta t] extracts the meta-data from the document in yaml format *)

  val body_string : t -> string
  (** [body_string t] extracts the body of the document as a string *)

  val body_md : t -> Omd.doc
  (** [body_md t] extracts the body of the document in Omd markdown format *)

  val to_html : t -> Tyxml.Html.doc
  (** [to_html t] takes a [t] and makes a web page *)

  val index_html : t list -> Tyxml.Html.doc
  (** [index_html ts] takes a list of [ts] and produces an index of those *)

  val pp_contents : Format.formatter -> t -> unit
  (** Pretty print the contents of the document *)
end

(** [Make (M)] is the recommended way to generate a Collection module -- you
    provide the [Meta] module which can use
    {{:https://github.com/patricoferris/ppx_deriving_yaml} ppx_deriving_yaml} to
    automatically generate the [of_yaml] and [to_yaml] functions. *)
module Make (M : Meta) : S with type meta = M.t

(** {[
      open Sesame

      module M : Collection.Meta = struct
        type t = { title : string } [@@deriving yaml]
      end

      module C = Collection.Make (M)
    ]}*)
