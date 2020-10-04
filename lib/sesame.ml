(** {1 Sesame}

    A small build tool for static blogs and sites with a mission to help reduce
    site size and promote good accessibility practices. *)

(** {2 Building} *)

module Collection = Collection
(** [Collections] are groups of documents which share the same shape of meta
    data *)

module Components = Components
(** [Components] contains some useful [Txyml.Html] element and document
    geneators for when you want to customise your build process *)

module Build = Build
(** [Build] takes a [Collection] and produces useful builder functions *)

module Image = Image
(** A small library for manipulating images *)

module Files = Files
(** A small library for handling files *)

(** {2 Checking}*)

module Access = Access
(** [Access] contains functions for checking whether code meets some
    accessibility standards *)

module Checks = Checks
(** The framework that [Access] is built on, exposed so you can write your own
    checks. Completely inspired by Alcotest *)
