open Checks
(** A predefined collection of accessibility checks over Markdown and HTML
    documents that you are free to integrate into your build process *)

(** {1 Markdown Checkables} *)

val well_nested_headers : Omd.doc checkable
(** This checks for headers that move sequentially downwards in your markdown --
    you should not have a header H1 and then a header H3 without going through
    H2 first. This does not enforce headers to do the same when stepping back up
    i.e. a H4 can be followed by a H2. *)
