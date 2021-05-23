(** {1 Collections}

    Collections are at the very heart of Sesame and was the first thing Sesame
    could do. A Collection is simply a set of files that share the same metadata
    structure. This is expressed in the "Jekyll Format", a header (frontmatter)
    of yaml followed by markdown.

    Once you have specified the shape of the metadata using types, Sesame can
    more or less handle the rest until you want to customise the output which
    you most likely will! *)

module type Meta = sig
  type t [@@deriving yaml]
  (** The type for metadata *)
end

(** {2 Make a Collection}

    This module creates a collection from a file *)

module Make (M : Meta) : sig
  type meta = M.t

  type t = { path : string; meta : M.t; body : string }

  include S.S with type Input.t = Fpath.t and type t := t and type Output.t = t
end

(** {2 Make HTML Output}

    The [HTML] functor generates a string of HTML based on some metadata (i.e. a
    collection), it also passes through the original path of the collection the
    HTML was generated from. *)

module Html (M : Meta) : sig
  type t = { path : string; html : string }

  include
    S.S with type Input.t = Make(M).t and type t := t and type Output.t = t
end
