type t = { ext : Images.format; image : OImages.rgb24_class }

let from_file filename =
  match Filename.extension filename with
  | ".png" ->
      {
        ext = Images.Png;
        image = OImages.rgb24 @@ OImages.make @@ Png.load_as_rgb24 filename [];
      }
  | ".jpeg" | ".jpg" ->
      { ext = Images.Jpeg; image = OImages.rgb24 @@ OImages.load filename [] }
  | s -> raise (Failure ("We don't currently support: " ^ s))

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
  img.image#save output (Some img.ext) [ Images.Save_Quality quality ]

let of_string width height ext str =
  let r = new OImages.rgb24_with in
  { ext; image = r width height [] @@ Bytes.of_string str }

let to_string img = Bytes.to_string img.image#dump

let v ext w h image =
  match ext with
  | "png" -> of_string w h Images.Png image
  | "jpeg" -> of_string w h Images.Jpeg image
  | _ -> raise (Failure ("Extension not supported: " ^ ext))

let transform ?(quality = 60) ?(prefix = "modified-") ~src ~ext ~dst transforms
    =
  let files =
    Files.all_files src |> List.filter (fun f -> Filename.extension f = ext)
  in
  List.iter
    (fun f ->
      let img = try from_file f with Images.Wrong_file_type -> failwith f in
      let img = List.fold_left (fun a t -> t a) img transforms in
      try to_file ~quality img (dst ^ "/" ^ prefix ^ Filename.basename f) with
      | Failure fail -> failwith (f ^ " " ^ fail)
      | f -> raise f)
    files
