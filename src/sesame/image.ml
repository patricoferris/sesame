type t = {
  ext : Images.format;
  path : Fpath.t;
  width : int;
  height : int;
  image : OImages.rgb24_class;
}

let from_file path =
  try
    match Fpath.get_ext path with
    | ".png" ->
        let image =
          OImages.rgb24 @@ OImages.make
          @@ Png.load_as_rgb24 (Fpath.to_string path) []
        in
        {
          ext = Images.Png;
          path;
          width = image#width;
          height = image#height;
          image;
        }
    | ".jpeg" | ".jpg" ->
        let image =
          OImages.rgb24 @@ OImages.make @@ Jpeg.load (Fpath.to_string path) []
        in
        {
          ext = Images.Jpeg;
          path;
          width = image#width;
          height = image#height;
          image;
        }
    | s -> raise (Failure ("We don't currently support: " ^ s))
  with _ -> failwith (Fmt.str "Failed to open %a" Fpath.pp path)

let encode t =
  let yaml : Yaml.value =
    `O
      [
        ("path", `String (Fpath.to_string t.path));
        ( "image",
          (* Hashing the image contents... ? *)
          `String
            (Bytes.to_string t.image#dump
            |> Digestif.SHA1.digest_string |> Digestif.SHA1.to_raw_string) );
      ]
  in
  Fmt.str "%a" Yaml.pp yaml

let decode s =
  match Yaml.of_string_exn s with
  | `O [ ("path", `String path); ("image", `String _hash) ] ->
      from_file (Fpath.v path)
  | _ -> failwith "Error decoding image from string"

let cap v = if v < 0 then 0 else if v > 255 then 255 else v

let threshold thresholds (rgb : Color.rgb) : Color.rgb =
  let thresholdsf = float_of_int thresholds in
  let r =
    int_of_float (floor (thresholdsf *. float_of_int rgb.r /. 255.))
    * (255 / thresholds)
  in
  let g =
    int_of_float (floor (thresholdsf *. float_of_int rgb.g /. 255.))
    * (255 / thresholds)
  in
  let b =
    int_of_float (floor (thresholdsf *. float_of_int rgb.b /. 255.))
    * (255 / thresholds)
  in
  { r; g; b }

let ( +% ) (c : Color.rgb) (a : Color.rgb) : Color.rgb =
  { r = cap (c.r + a.r); g = cap (c.g + a.g); b = cap (c.b + a.b) }

let ( *% ) (c : Color.rgb) s : Color.rgb =
  let mult i f = int_of_float (float_of_int i *. f) in
  { r = cap (mult c.r s); g = cap (mult c.g s); b = cap (mult c.b s) }

let mono t =
  let img = t.image in
  for x = 0 to img#width - 1 do
    for y = 0 to img#height - 1 do
      let rgb = img#get x y in
      let mono = Color.brightness rgb in
      img#set x y { r = mono; g = mono; b = mono }
    done
  done;
  { t with image = img }

type dither = [ `FS ]

type color = [ `Normal | `Mono ]

let fs_dither mode levels t =
  let diff (a : Color.rgb) (b : Color.rgb) : Color.rgb =
    { r = cap (a.r - b.r); g = cap (a.g - b.g); b = cap (a.b - b.b) }
  in

  let img = if mode = `Mono then (mono t).image else t.image in
  for y = 0 to img#height - 2 do
    for x = 1 to img#width - 2 do
      let old_pixel = img#get x y in
      let new_pixel = threshold levels old_pixel in
      img#set x y new_pixel;
      let err = diff old_pixel new_pixel in
      img#set (x + 1) y (img#get (x + 1) y +% (err *% (7. /. 16.)));
      img#set (x - 1) (y + 1) (img#get (x - 1) (y + 1) +% (err *% (3. /. 16.)));
      img#set x (y + 1) (img#get x (y + 1) +% (err *% (5. /. 16.)));
      img#set (x + 1) (y + 1) (img#get (x + 1) (y + 1) +% (err *% (1. /. 16.)))
    done
  done;
  { t with image = img }

let dither ?(mode = `FS) ?(color = `Normal) ?(levels = 4) t =
  match mode with `FS -> fs_dither color levels t

let resize width t =
  let img = t.image in
  let sf = width /. float_of_int img#width in
  let height = truncate (float_of_int img#height *. sf) in
  let image = img#resize None (truncate width) height in
  { t with image }

let to_file ?(quality = 60) img output =
  img.image#save (Fpath.to_string output) (Some img.ext)
    [ Images.Save_Quality quality ]

module Transform = struct
  type conf = {
    quality : int;
    rename : string -> string;
    files : Fpath.t list;
    dst : Fpath.t;
  }

  let transform ~conf transforms =
    let { quality; rename; files; dst } = conf in
    List.iter
      (fun f ->
        let img =
          try from_file f
          with Images.Wrong_file_type -> failwith (Fpath.to_string f)
        in
        let img = List.fold_left (fun a t -> t a) img transforms in
        let output = Fpath.(dst // Path.change_filename f rename) in
        try to_file ~quality img output with
        | Failure fail -> failwith (Fpath.to_string output ^ " " ^ fail)
        | f -> raise f)
      files
end
