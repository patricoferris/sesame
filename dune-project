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
 (synopsis "A Simple Static Site Generator")
 (description
   "Sesame can build simple static sites from Jeykll-format documents")
 (depends
  (alcotest :with-test)
  (bos :with-test)))

(package
 (name current-sesame)
 (synopsis "The OCurrent-powered Static Site Generator")
 (description
   "Current-sesame builds on top of Sesame providing a toolkit of OCurrent-powered modules for building more complex pipelines that ultimately build websites")
 (depends
  (alcotest :with-test)
  (bos :with-test)))
