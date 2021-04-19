open Sesame

let test_file = "./rory.jpeg"

let output_file = "./modified-rory.jpeg"

let files = [ Fpath.v test_file ]

let filesize f = (Unix.stat f).st_size

let transform () =
  let conf : Image.Transform.conf =
    { quality = 30; prefix = "modified-"; files; dst = Fpath.v "./" }
  in
  Image.Transform.transform ~conf [ Image.resize 200.; Image.dither ~levels:1 ]

let () =
  transform ();
  Format.printf "Original Filesize: %i\nModified Filesize: %i\n"
    (filesize test_file) (filesize output_file)
