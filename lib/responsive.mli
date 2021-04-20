(** {2 Tools for Responsive Web Pages}

    This modules contains different tools for building more responsive web
    pages. In particular, its biggest selling feature is the responsive images
    module which can generate [<img srcset=...>] HTML tags from a source image
    i.e. it can create the rescaled images, save them somewhere and give back to
    you the HTML tag to use as you see fit *)

(** @inline *)
module Images : sig
  (** {2 Generate Responsive Images} *)

  type t = MaxWidth of int * int * t | Default of int

  (** The media type allows you specify how the responsive image generator show
      create new resized images allowing with the media conditions to add to the
      image srcset attribute. *)

  type conf = { root : Fpath.t; conf : Image.Transform.conf }
  (** A slightly extended image conf, you need to also provide the file to which
      the images are relative too. *)

  val v :
    alt:string ->
    conf:conf ->
    t ->
    (Fpath.t * [> Html_types.img ] Tyxml_html.elt) list
  (** [v ~alt ~conf t] applies the responsive image optimisations to all of the
      images in the transformation configuration, [conf], and produces an image
      srcset for each (it returns an association list with key being the
      original image's filepath). *)
end
