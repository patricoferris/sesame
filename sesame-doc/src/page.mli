module Meta : sig
  type t [@@deriving yaml]

  val title : t -> string

  val description : t -> string

  val default :
    title:string -> description:string -> author:string -> date:string -> t
end

module C : sig
  include Sesame.Collection.S

  val get_title : t -> string

  val build_html :
    t ->
    [< Html_types.flow5 > `Div `PCDATA ] Tyxml_html.elt ->
    [ `Html ] Tyxml_html.elt
end

module Builder : Sesame.Build.S
