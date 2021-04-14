module type Meta = sig
  type t [@@deriving yaml]
end

module Make (M : Meta) : sig
  type meta = M.t

  module A : sig
    type t = { path : string; meta : M.t; body : string }
  end

  type t = A.t

  include
    S.S with type Input.t = Fpath.t and type t := A.t and type Output.t = A.t
end

module Html (M : Meta) : sig
  type t = string

  include
    S.S with type Input.t = Make(M).t and type t := t and type Output.t = t
end
