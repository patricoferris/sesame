module Meta : sig
  include Sesame.Collection.Meta

  type page = { title : string; description : string }

  val make : title:string -> description:string -> t

  val make_page : title:string -> description:string -> page

  val get_pages : t -> page list

  val add_page : t -> page -> t
end

val section_page_of_page : Page.Meta.t -> Meta.page

module C : sig
  include Sesame.Collection.S

  val get_title : t -> string

  val add_page : t -> Meta.page -> t

  val sidebar : string -> string -> t list -> [> Html_types.div ] Tyxml.Html.elt

  val build_html :
    t -> [< Html_types.flow5 > `Div `PCDATA ] Tyxml.Html.elt -> Tyxml.Html.doc
end

module Builder : Sesame.Build.S
