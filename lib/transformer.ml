module Toc = struct
  open Tyxml

  type t = heading list

  and heading = H of int * string

  let to_string (H (size, text)) = "H" ^ string_of_int size ^ " " ^ text

  let get_int = function H (i, _) -> i

  let toc doc =
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

  let transform doc =
    let f (b : Omd.block) =
      match b.bl_desc with
      | Omd.Heading (_s, il) -> (
          match il.il_desc with
          | Omd.Text heading ->
              {
                b with
                bl_attributes =
                  ("id", Files.title_to_dirname heading) :: b.bl_attributes;
              }
          | _ -> b)
      | _ -> b
    in
    List.map f doc

  type 'a tree = Br of 'a * 'a tree list

  let rec pre ppf tree =
    match tree with
    | Br (t, lst) ->
        Format.pp_print_string ppf (to_string t);
        List.iter (pre ppf) lst

  (* An algorithm to turn a list of headers into a
     tree of headers *)
  let to_tree lst =
    let arr = Array.init 7 (fun i -> Br (H (i, ""), [])) in
    let rec tidy arr until = function
      | n when n <= until -> ()
      | n ->
          let t = arr.(n) in
          let (Br (v, lst)) = arr.(n - 1) in
          arr.(n - 1) <- Br (v, lst @ [ t ]);
          tidy arr until (n - 1)
    in
    let rec aux last = function
      | [] ->
          tidy arr 0 last;
          arr.(0)
      | [ a ] ->
          let x = get_int a in
          arr.(x) <- Br (a, []);
          aux x []
      | a :: b :: xs ->
          let x = get_int a in
          let y = get_int b in
          let _t = arr.(x) in
          let (Br (p, lst)) = arr.(x - 1) in
          if x = y then (
            arr.(x - 1) <- Br (p, lst @ [ Br (a, []) ]);
            aux x (b :: xs))
          else if x > y then (
            arr.(x) <- Br (a, []);
            tidy arr (y - 1) x;
            aux x (b :: xs))
          else (
            arr.(x) <- Br (a, []);
            aux x (b :: xs))
    in
    aux 0 lst

  let map_to_item h =
    let to_elt cl link txt =
      [%html "<a class=" cl " href=" ("#" ^ link) ">" [ Html.txt txt ] "</a>"]
    in
    match h with
    | H (i, txt) ->
        if String.equal txt "" then []
        else
          [
            to_elt
              [ "toc-link"; "toc-item-" ^ string_of_int i ]
              (Files.title_to_dirname txt)
              txt;
          ]

  (* Nested List Spec: https://developer.mozilla.org/en-US/docs/Learn/HTML/Introduction_to_HTML/HTML_text_fundamentals *)
  let rec preorder = function
    | Br (v, []) ->
        [%html
          "<ul class='toc'><li class='toc-li'>" (map_to_item v) "</li></ul>"]
    | Br (v, lst) ->
        [%html
          "<ul class='toc'><li>"
            (map_to_item v
            @ List.fold_left (fun acc v -> acc @ [ preorder v ]) [] lst)
            "</li></ul>"]

  let pp ppf t =
    List.iter (fun h -> Format.pp_print_string ppf (to_string h ^ "\n")) t

  (* Accessibility Check: https://usability.yale.edu/web-accessibility/articles/headings *)
  let rec accessibility = function
    | x :: y :: ys ->
        let a = get_int x in
        let b = get_int y in
        if get_int x < get_int y then
          if b - a = 1 then accessibility (y :: ys)
          else raise (Failure "Failed because of inproper heading nesting")
    | _ -> assert true

  let to_html toc =
    (try accessibility toc
     with Failure t ->
       print_endline "== Failed Heading List ==";
       pp Format.std_formatter toc;
       raise (Failure t));
    let tree = to_tree toc in
    preorder tree |> fun list ->
    [%html
      "<details><summary>Table of Contents</summary>" [ list ] "</details>"]
end
