open Tyxml

let html ?(lang = "en") ~title ~description ~body =
  [%html {| 
    <!DOCTYPE html>
    <html lang='|} lang {|'>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta name="description" content="|}
      description
      {|"> 
      <link rel="stylesheet" href="/styles.css">
      <title>|} (Html.txt title) {|</title>
    </head>
    <body>
      |} body {|
    </body>
    </html>
  |}] [@@ocamlformat "disable"]
