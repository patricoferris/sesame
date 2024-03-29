---
title: OCaml.org
description: OCaml is an industrial-strength programming language supporting functional, imperative and object-oriented styles
releases: Recent OCaml Releases
heroImage: static/images/camel.jpeg
heroAlt: "An image of camel standing in the desert, the image has been dithered"
---

```ocaml
(* Binary tree with leaves car­rying an integer. *)
type tree = Leaf of int | Node of tree * tree

let rec exists_leaf test tree =
  match tree with
  | Leaf v -> test v
  | Node (left, right) ->
      exists_leaf test left
      || exists_leaf test right

let has_even_leaf tree =
  exists_leaf (fun n -> n mod 2 = 0) tree
```