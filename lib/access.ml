type heading = H of int * string

let get_int = function H (i, _) -> i

let headings doc =
  let rec loop acc = function
    | [] -> List.rev acc
    | (b : Omd.block) :: bs -> (
        match b.bl_desc with
        | Omd.Heading (s, il) -> (
            match il.il_desc with
            | Omd.Text heading -> loop (H (s, heading) :: acc) bs
            | _ -> loop acc bs)
        | _ -> loop acc bs)
  in
  loop [] doc

let well_nested_headers =
  let rec nested = function
    | x :: y :: ys ->
        let a = get_int x in
        let b = get_int y in
        if get_int x < get_int y then
          if b - a = 1 then nested (y :: ys) else false
        else false
    | _ -> true
  in
  let check omd = headings omd |> nested in
  Checks.md check
