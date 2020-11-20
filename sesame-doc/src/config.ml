open Cmdliner

let content_dir =
  let docv = "CONTENT-DIR" in
  let doc = "The location under which your documentation lies" in
  Arg.(value & opt string "src" & info ~doc ~docv [ "content-dir" ])

let dist_dir =
  let docv = "DIST-DIR" in
  let doc =
    "The location under which your documentation site will be placed after \
     building"
  in
  Arg.(value & opt string "docs" & info ~doc ~docv [ "dist-dir" ])

let section n = n ^ "-section"

let change_root c_dir d_dir path =
  try
    let d_dir = Fpath.v d_dir in
    let top = Fpath.v c_dir in
    let rest = Fpath.relativize ~root:top path in
    match rest with
    | Some s -> Fpath.(d_dir // s |> to_string)
    | None -> Fmt.failwith "Convert the root directory failed"
  with Invalid_argument m -> Fmt.failwith "Change root failed: %s" m

let remove_root c_dir path =
  try
    let top = Fpath.v c_dir in
    let rest = Fpath.relativize ~root:top path in
    match rest with
    | Some s -> Fpath.(s |> to_string)
    | None -> Fmt.failwith "Convert the root directory failed"
  with Invalid_argument m -> Fmt.failwith "Change root failed: %s" m
