(lang dune 2.7)

(name sesame)

(generate_opam_files true)

(source
 (github patricoferris/sesame))

(license ISC)

(authors "Patrick Ferris")

(maintainers "pf341@patricoferris.com")

(package
 (name sesame)
 (synopsis "Sesame: blog builder")
 (description "Build less resource intensive blogs with Sesame")
 (depends yaml tyxml omd jekyll-format ppx_deriving_yaml camlimages))
