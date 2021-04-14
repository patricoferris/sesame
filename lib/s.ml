module type Encodeable = sig
  type t
  (** The type of values *)

  val encode : t -> string
  (** [encode t] should marshal [t] *)

  val decode : string -> t
  (** [decode s] should reproduce a [t] from a string [s] *)

  val pp : t Fmt.t
  (** Pretty-printer for values *)
end

module type S = sig
  module Input : Encodeable

  type t

  module Output : Encodeable with type t = t

  val build : Input.t -> (Output.t, [ `Msg of string ]) Lwt_result.t
  (** [build t] takes the data [t] and produces an output depending on the [Value.t] *)
end
