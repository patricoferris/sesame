module Conf = Config
open Httpaf
open Lwt.Infix
open Httpaf_lwt_unix
open Sesame

let info ppf = Fmt.pf ppf "[explore.ocaml] %a \n%!"

let handle_error = function Ok t -> t | Error (`Msg m) -> failwith m

let router ?(top_dir = "content") = function
  | [ ""; "" ] | [ "" ] | [ "/" ] ->
      Files.read_file ("./" ^ top_dir ^ "/index.html") |> handle_error
  | f -> (
      let path = "./" ^ top_dir ^ String.concat "/" f in
      match Files.read_file path with
      | Ok f -> f
      | Error (`Msg _) -> Files.read_file (path ^ "/index.html") |> handle_error
      )

let get_content_type s =
  let ct s = ("Content-Type", s) in
  match Filename.extension s with
  | ".html" -> ct "text/html"
  | ".css" -> ct "text/css"
  | ".js" -> ct "text/javascript"
  | ".png" -> ct "image/png"
  | ".jpg" | ".jpeg" -> ct "image/jpeg"
  | ".svg" -> ct "image/svg+xml"
  | _ -> ct "text/html"

let handle_get c_dir d_dir reqd =
  match Reqd.request reqd with
  | { Request.meth = `GET; Request.target = t; _ } ->
      ignore (Builder.build c_dir d_dir);
      let str = router ~top_dir:d_dir (String.split_on_char '/' t) in
      let resp =
        let content_type = get_content_type t in
        Response.create
          ~headers:
            (Headers.of_list
               [
                 content_type;
                 ("Content-length", string_of_int (String.length str));
               ])
          `OK
      in
      info Fmt.stdout (fun ppf t -> Fmt.pf ppf "Handling GET request: %s" t) t;
      Reqd.respond_with_string reqd resp str
  | _ ->
      let headers = Headers.of_list [ ("connection", "close") ] in
      Reqd.respond_with_string reqd
        (Response.create ~headers `Method_not_allowed)
        ""

let error_handler ?request:_ error start_response =
  let response_body = start_response Headers.empty in
  (match error with
  | `Exn _ ->
      Body.write_string response_body "Something went wrong";
      Body.write_string response_body "\n"
  | #Status.standard as error ->
      Body.write_string response_body (Status.default_reason_phrase error));
  Body.close_writer response_body

let serve port c_dir d_dir =
  info Fmt.stdout
    (fun ppf a -> Fmt.pf ppf "Starting server at: http://localhost:%i" a)
    port;
  let promise, _resolver = Lwt.wait () in
  let request_handler (_ : Unix.sockaddr) = handle_get c_dir d_dir in
  let error_handler (_ : Unix.sockaddr) = error_handler in
  let localhost = Unix.inet_addr_loopback in
  Lwt.async (fun () ->
      Lwt_io.establish_server_with_client_socket
        (Unix.ADDR_INET (localhost, port))
        (Server.create_connection_handler ~request_handler ~error_handler)
      >|= fun _ -> ());
  Lwt_main.run promise

(* Command Line Tool *)
open Cmdliner

let run port = serve port

let port =
  let docv = "PORT" in
  let doc = "Specifiy the port the local server should run on." in
  Arg.(value & pos 0 int 8000 & info ~doc ~docv [])

let info =
  let doc =
    "Run a local server which serves the contents of content. It rebuilds the \
     entire site for each page load so changes made will be automatically \
     synced."
  in
  Term.info ~doc "dev"

let cmd = (Term.(pure run $ port $ Conf.content_dir $ Conf.dist_dir), info)
