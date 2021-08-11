module FileContents = struct
  type t = [ `Blob of string option ] [@@deriving yojson]
end

module Release = struct
  module Uri = struct
    type t = Uri.t

    let of_yojson = function
      | `String s -> Ok (Uri.of_string s)
      | _ -> Error "Expected String"

    let to_yojson t = `String (Uri.to_string t)
  end

  module Ptime = struct
    type t = Ptime.t

    let of_yojson json =
      match Ptime.of_rfc3339 (Yojson.Safe.Util.to_string json) with
      | Ok (time, _, _) -> Ok time
      | Error (`RFC3339 (_, err)) ->
          Error (Fmt.str "%a" Ptime.pp_rfc3339_error err)

    let to_yojson t = `String (Ptime.to_rfc3339 t)
  end

  type r = { name : string; created_at : Ptime.t; url : Uri.t }
  [@@deriving yojson]

  type t = r option array array [@@deriving yojson]
end

module File = struct
  type t = string [@@deriving yojson]
end

module Files = struct
  type entry = { name : string } [@@deriving yojson]

  type t = entry array [@@deriving yojson]
end
