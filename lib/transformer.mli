module Toc : sig
  type t = heading list

  and heading = H of int * string

  val toc : Omd.doc -> t

  type 'a tree = Br of 'a * 'a tree list

  val to_tree : t -> heading tree

  val transform : Omd.doc -> Omd.doc

  val preorder :
    heading tree -> [< Html_types.li_content_fun > `A `Ul ] Tyxml.Html.elt

  val to_html : t -> [> Html_types.details ] Tyxml.Html.elt
end

module Image : sig
  type t
  (** Some configuration for the images being transformed in a markdown file *)

  val v : quality:int -> path:Fpath.t -> dst:Fpath.t -> Responsive.Images.t -> t
  (** [v ~quality ~dst responsive] is a constructor for this transform's
      configuration value *)

  val transform : t -> Omd.doc -> Omd.doc
  (** [transform t doc] transforms all of the images in [doc] a specified by the
      configuration *)
end
