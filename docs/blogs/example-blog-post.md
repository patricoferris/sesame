---
title: "Hello World"
description: "An example blogpost"
date: 2020-10-23 18:00:41
author: "Patrick Ferris" 
tags: ["coding", "ocaml"]
image: ../images/camel.jpg
credit: "Image by Simon Matzinger and can be found on Pexels by searching Camel" 
---

A simple blogpost example. 

The original image file was `1.7m` this `Sesame` generated one is only `40k`. 

```ocaml
let () = print_endline "Hello World" 
```

Another thing that is cool, is that the build process has (limited) accessibility checks built-in!

```ocaml
let _access_header_check =
      Checks.check ~exit:false "Headers" Access.well_nested_headers md
```

This check catches the following mistake at build time:

# Bad nesting

### Header

An `H1` followed by an `H3` is an example of bad nesting, you can read more about it in [the web accessibility guidelines](https://webaim.org/techniques/semanticstructure/) on semantic structure.