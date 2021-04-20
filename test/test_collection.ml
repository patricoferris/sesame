open Lwt.Infix

module Meta = struct
  type t = { title : string; description : string } [@@deriving yaml]
end

module C = Sesame.Collection.Make (Meta)
module H = Sesame.Collection.Html (Meta)

let free () =
  print_endline "freeing all resources";
  Lwt.return ()

let msg =
  let pp ppf (`Msg s) = Fmt.pf ppf "%s" s in
  Alcotest.of_pp pp

let collection = Alcotest.of_pp C.Output.pp

let test_collection_gen switch () =
  Lwt_switch.add_hook (Some switch) free;
  C.build (Fpath.v "./index.md") >|= fun c ->
  Alcotest.(check (result collection msg)) "same collection" c c

let tests = [ Alcotest_lwt.test_case "collection" `Quick test_collection_gen ]
