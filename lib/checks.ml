module type CHECKABLE = sig
  type t
  (** The type for accessibility checks *)

  val pp : Format.formatter -> t -> unit
  (** A pretty printer for the check *)

  val check : t -> bool
  (** The check *)
end

exception Check_error

type 'a checkable = (module CHECKABLE with type t = 'a)

let checkable (type a) (pp : a Fmt.t) (check : a -> bool) : a checkable =
  let module M = struct
    type t = a

    let pp = pp

    let check = check
  end in
  (module M)

let md (check : Omd.doc -> bool) : Omd.doc checkable =
  let pp_omd ppf omd = Fmt.pf ppf "%s" (Omd.to_sexp omd) in
  checkable pp_omd check

let html (check : Tyxml.Html.doc -> bool) : Tyxml.Html.doc checkable =
  let pp_html = Tyxml.Html.pp ~indent:true () in
  checkable pp_html check

let pp (type a) (c : a checkable) =
  let (module T) = c in
  T.pp

let checker (type a) (c : a checkable) =
  let (module T) = c in
  T.check

let check ?(exit = true) msg checkable t =
  let open Pp in
  let b = checker checkable @@ t in
  if b then Fmt.(pf stdout "[ %a ] %s" pass "PASS" msg)
  else (
    Fmt.(pf stdout "[ %a ] %s\n %a" fail "FAIL" msg (pp checkable) t);
    if exit then raise Check_error else ())
