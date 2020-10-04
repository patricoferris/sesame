(** Based entirely on the excellent unit testing framework: Alcotest *)

module type CHECKABLE = sig
  type t
  (** The type for accessibility checks *)

  val pp : Format.formatter -> t -> unit
  (** A pretty printer for the check *)

  val check : t -> bool
  (** The check *)
end

type 'a checkable = (module CHECKABLE with type t = 'a)

val checkable : 'a Fmt.t -> ('a -> bool) -> 'a checkable
(** Checkable constructor *)

val md : (Omd.doc -> bool) -> Omd.doc checkable
(** Predefined markdown checkable *)

val html : (Tyxml.Html.doc -> bool) -> Tyxml.Html.doc checkable
(** Predefined Tyxml HTML checkable *)

val check : ?exit:bool -> string -> 'a checkable -> 'a -> unit
(** [check msg checkable t] performs a check on [t] using [checkable] described
    by [msg]. If you don't want the function to fail if the check fails then
    pass [~exit:false] *)
