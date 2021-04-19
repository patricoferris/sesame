let omd =
  let pp ppf omd = Fmt.pf ppf "%s" (Omd.to_sexp omd) in
  Alcotest.of_pp pp
