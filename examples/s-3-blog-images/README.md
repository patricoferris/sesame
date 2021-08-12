Sesame Blog and Image Optimisation
----------------------------------

In this continuation of the blog example, we also process the blogs for any images and produce new images of different sizes to optimise the experience for mobile users.

This is accomplished with the responsive image transformer. In particular when generating a blog not only convert the markdown to HTML but replace instances of the image with a modified responsive image element and process the image itself to generate multiple sizes.

The entire blog build function is just:

```ocaml
let build (t : C.t) =
    let conf =
      Transformer.Image.v ~quality:50 ~path:(Fpath.v t.path)
        ~dst:out
        Responsive.Images.(MaxWidth (660, 400, Default 800))
    in
    let omd = Omd.of_string t.body |> Sesame.Transformer.Image.transform conf in
    let body =
      [
        Tyxml.Html.div
          [ Tyxml.Html.Unsafe.data (Omd.to_html omd) ];
      ]
    in
    Components.html ~title:t.meta.title ~description:t.meta.description ~body ()
    |> fun html ->
    { path = t.path; html = Fmt.str "%a" (Tyxml.Html.pp ()) html }
    |> Lwt_result.return
```