open Current.Syntax

let save = Current_fs.save

let read path =
  Current.component "read"
  |> let> path = path in
     Current_incr.const (Bos.OS.File.read path, None)

let read_dir ?filter:_ path =
  let+ path = path in
  let files = Bos.OS.Dir.contents path |> Rresult.R.get_ok in
  List.map
    (fun r -> Bos.OS.File.read r |> fun read -> (r, Rresult.R.get_ok read))
    files
