Sesame 🌱
---------

A library of tools for building smaller, greener, less resource intensive website and blogs inspired by [Low Tech Magazine](https://solar.lowtechmagazine.com/)

## User Guide

Sesame is built on the idea of `Collection`s -- these are groups of documents that share common meta-data. The should be formatted using the [Jekyll Format](https://jekyllrb.com/docs/front-matter/) with `yaml` front-matter separating the body from the meta-data. It exposes functors to build a `Collection` from an OCaml description of the meta-data.

### Meta data

You must provide an interface corresponding to `Meta` in order to build a collection. Luckily [tools exist](https://github.com/patricoferris/ppx_deriving_yaml) that make this incredibly simple.

```ocaml
module M = struct 
  type t = { title: string; authors : string list} [@@deriving yaml]
end 
```

Which corresponds to the markdown file: 


```markdown
---
title: My first blog post
authors: 
  - Alice 
---

Once upon a time...
```

### Making a collection

Once you have your `Meta` interface, you can pass this to the `Collection` maker to get a full collection module. 

```ocaml
module C = Collection.Make(M)
```

What about customisability? What if I do not want the default `to_html` function which just transforms the body. You can override these functions using `include`. 

```ocaml
module Custom = struct
  include Collection.Make (M)

  let to_html (_ : t) = "<h1>Hello World</h1>"
end
```

### Building a collection 

With a new collection in hand you can then generate the functions for building the collection i.e. outputting HTML files. 

```ocaml
module B = Build.Make(C)

B.build ~src_dir:"blog" ~dest_dir:"dist/blog"
```

And that's all there is to it. 

## Images 

One of the biggest sources of website size (and therefore energy consumption and time spent waiting) are in the images. They tend to be large files. Sesame exposes an `Image` module which can perform some optimisations on a directory containing images. Common operations are resizing, dithering and converting to use less colours.
