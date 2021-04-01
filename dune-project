(lang dune 2.7)
(name sesame)
(generate_opam_files true)
(source (github patricoferris/sesame))
(license ISC)
(authors "Patrick Ferris")
(maintainers "pf341@patricoferris.com")
(package
 (name sesame)
 (synopsis "Sesame: blog builder")
 (description "Build less resource intensive blogs with Sesame")
 (depends
  (tyxml-ppx (>= 4.4.0))
  (ptime (>= 0.8.5))
  (fmt (>= 0.8.9))
  yaml
  bos
  tyxml
  omd
  jekyll-format
  ppx_deriving_yaml
  camlimages))
(package
 (name sesame-doc)
 (synopsis "Long-form documentation builder using sesame")
 (description
  "A command-line tool for generating long-form documentation that works well with ocaml-mdx")
 (depends
  (tyxml-ppx (>= 4.4.0))
  (ppx_deriving_yaml (>= 0.1.0))
  sesame
  fmt
  rresult
  cmdliner
  hilite
  httpaf
  httpaf-lwt-unix
  lwt))
(package
 (name current_sesame)
 (synopsis "Sesame plugin for OCurrent")
 (description
  "A small plugin for building static-sites using an OCurrent pipeline")
 (depends
  (current_web (>= 0.3))
  (current_github (>= 0.3))
  (current (>= 0.3))
  (ppx_deriving_yaml (>= 0.1.0))
  lwt))
