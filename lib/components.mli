open Tyxml
(** Useful HTML component functions that you can use to build basic websites *)

val html :
  ?lang:string ->
  ?css:string ->
  title:string ->
  description:string ->
  body:[< Html_types.flow5 > `PCDATA ] Html.elt list ->
  Html.doc
(** [html ~title ~description ~body] will construct an HTML document with the
    meta field set to [description] the title field set to [title] and the body
    set to [body]. You can also provide an optional language (default 'en') *)
