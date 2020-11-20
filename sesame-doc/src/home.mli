module Meta : Sesame.Collection.Meta
(** Homepage metadata *)

module C : sig
  include Sesame.Collection.S

  val get_title : t -> string

  val build_html :
    t ->
    [< Html_types.flow5 > `Div `PCDATA ] Tyxml_html.elt ->
    [ `Html ] Tyxml_html.elt
end

module Builder : Sesame.Build.S
