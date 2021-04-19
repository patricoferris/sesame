type t
(** The type of images *)

val resize : float -> t -> t
(** Resizing images based on scaling the width to fit the argument and the
    height using the same scale factor *)

val from_file : Fpath.t -> t
(** [from_file path] loads the image from [path] *)

val to_file : ?quality:int -> t -> Fpath.t -> unit
(** [to_file t path] will put the image [t] in a file at [path] -- the [quality]
    option is used for jpeg images and default to [60] *)

val mono : t -> t
(** Transform an image [t] to a black and white image *)

type dither = [ `FS ]
(** Dithering algorithms:

    - FS: Floyd-Steinberg *)

type color = [ `Normal | `Mono ]

val dither : ?mode:dither -> ?color:color -> ?levels:int -> t -> t
(** [dither ~mode ~color t] will dither an image using the algorithm specified
    by [mode] using the colors specified by [color] *)

module Transform : sig
  type conf = {
    quality : int;
    prefix : string;
    files : Fpath.t list;
    dst : Fpath.t;
  }
  (** A configuration for transformations *)

  val transform : conf:conf -> (t -> t) list -> unit
  (** [transform src ext dir transforms] will load all of the images in [src]
    ending with [ext] extension, it will then apply the list of [transforms] to
    the images before placing the output files in [dir]. The [prefix] option
    lets you add a prefix to the output image filename, the default being
    ["modified-"], the [quality] option let's you specify the jpeg quality
    defaulting to [60] *)
end

val encode : t -> string

val decode : string -> t
