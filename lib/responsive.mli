module Images : sig
  (** {2 Generate Responsive Images} *)

  type t =
    | MaxWidth of int * int * t
    | Default of int
        (** The media type allows you specify how the responsive image generator
            show create new resized images allowing with the media conditions to
            add to the image srcset attribute. *)

  val v :
    alt:string ->
    conf:Image.Transform.conf ->
    t ->
    (Fpath.t * [> Html_types.img ] Tyxml_html.elt) list
  (** [v ~alt ~conf t] applies the responsive image optimisations to all of the
      images in the transformation configuration, [conf], and produces an image
      srcset for each (it returns an association list with key being the
      original image's filepath). *)
end
