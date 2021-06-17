module Date : sig
  type t = Ptime.t

  val parse : Yojson.Basic.t -> t

  val serialize : t -> Yojson.Basic.t
end

module Url : sig
  type t = Uri.t

  val parse : Yojson.Basic.t -> t

  val serialize : t -> Yojson.Basic.t
end

type 'a res = ('a, [ `Msg of string ]) result

type conf = {
  token : string;
  owner : string;
  repo : string;
  name : string;
  email : string;
}
[@@deriving yojson]

module Make (C : Cohttp_lwt.S.Client) : sig
  val run_query :
    conf:conf ->
    parse:(Yojson.Basic.t -> 'a) ->
    query:string ->
    Yojson.Basic.t -> ('a, [> `Msg of string ]) result Lwt.t

  module FileContentQuery : sig
    val get :
      conf:conf ->
      branch:string ->
      string ->
      (Api.FileContents.t option, [> `Msg of string ]) result Lwt.t
  end

  module FileQuery : sig
    val get :
      conf:conf ->
      branch:string ->
      string ->
      (Api.File.t option, [> `Msg of string ]) result Lwt.t
  end

  module FilesQuery : sig
    val get : conf:conf -> (Api.Files.t, [> `Msg of string ]) result Lwt.t
  end

  module ReleasesQuery : sig
    val get : conf:conf -> Api.Release.t Lwt.t
  end
end
