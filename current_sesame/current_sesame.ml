module Local = Local
module Collection = Collection

module Simple = struct
  module Builder (Meta : Sesame.Collection.Meta) = struct
    module C = Sesame.Collection.Make (Meta)
    module CC = Collection.Builder (C)

    let pipeline ~src ~dst () =
      let files =
        Bos.OS.Dir.contents src |> Rresult.R.get_ok |> Current.return
      in
      let c = CC.build ~files in
      let index = CC.build_index c in
      let save_html c =
        let s = CC.to_html_string c in
        Current.bind
          (fun c ->
            let new_path =
              Sesame.Utils.html_path ~dir:(Some dst) (Fpath.v c.C.path)
            in
            Local.save (Current.return new_path) s)
          c
      in
      Current.all
        [
          Current.list_iter (module C) save_html c;
          Local.save Fpath.(dst / "index.html" |> Current.return) index;
        ]
  end
end
