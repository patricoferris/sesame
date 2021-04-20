Sesame 🌱
---------

A library of tools for building smaller, greener, less resource intensive and more accessible websites inspired by [Low Tech Magazine](https://solar.lowtechmagazine.com/). A few basic example exists inside `./examples`. 

 - `Sesame` contains the suite of tools, including transformations over markdown (ToC generation), responsive image generation, HTML output etc. 
 - `Current_sesame` takes those tools along with the rest of the [OCurrent ecosystem](https://github.com/ocurrent/ocurrent) and produces more tools for writing incremental site generators with hot-reloading if you want it!  

[API Documentation](https://patricoferris.github.io/sesame/)

## The main idea

Sesame is built on the idea of `Collection`s -- these are groups of documents that share common metadata. They should be formatted using the [Jekyll Format](https://jekyllrb.com/docs/front-matter/) with `yaml` frontmatter separating the body from the metadata.

### Collections & Metadata

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

From there it's up to you how the HTML is generated. Why not have a read of: 

 - The more [complete Sesame tutorial](https://patricoferris.github.io/sesame/sesame/index.html)
 - The [OCurrent-powered Site generator tutorial](https://patricoferris.github.io/sesame/current-sesame/index.html)
 - Or dive deep into a thorough example and read the source code for the "fake" ocaml.org site in `examples/ocaml`. 