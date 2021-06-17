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
  (alcotest-lwt
   (and
    (>= 1.3.0)
    :with-test))
  (ppx_deriving_yojson
   (>= 3.6.1))
  (digestif
   (>= 1.0.0))
  (yaml
   (>= 2.1.0))
  (uri
   (>= 4.1.0))
  (tyxml-ppx
   (>= 4.4.0))
  (tyxml
   (>= 4.4.0))
  (ppx_deriving_yaml
   (>= 0.1.0))
  (omd
   (>= 2.0.0~alpha1))
  (lwt
   (>= 5.4.0))
  (jekyll-format
   (>= 0.2.0))
  (fpath
   (>= 0.7.3))
  (fmt
   (>= 0.8.9))
  (cohttp-lwt-unix
   (>= 4.0.0))
  (cohttp
   (>= 4.0.0))
  (camlimages
   (>= 5.0.4))
  (alcotest :with-test)
  bos))

(package
 (name current-sesame)
 (synopsis "The OCurrent-powered Static Site Generator")
 (description
  "Current-sesame builds on top of Sesame providing a toolkit of OCurrent-powered modules for building more complex pipelines that ultimately build websites")
 (depends
  (irmin-watcher
   (>= 0.4.1))
  (sesame
   (= :version))
  (dream
   (>= ~dev))
  (ppx_deriving_yaml
   (and
    (>= 0.1.0)
    :with-test))
  (alcotest-lwt
   (and
    (>= 1.3.0)
    :with-test))
  (yojson
   (>= 1.7.0))
  (ptime
   (>= 0.8.5))
  (ppx_deriving_yojson
   (>= 3.6.1))
  (logs
   (>= 0.7.0))
  (graphql_ppx
   (>= 1.0.1))
  (fmt
   (>= 0.8.9))
  (current
   (>= 0.4))
  (cohttp-lwt
   (>= 4.0.0))
  (base64
   (>= 3.5.0))
  current_git
  (alcotest :with-test)
  (bos :with-test)))
