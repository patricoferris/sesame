let () =
  let open Alcotest_lwt in
  Lwt_main.run @@ run "Sesame" [ ("collections", Test_collection.tests) ]
