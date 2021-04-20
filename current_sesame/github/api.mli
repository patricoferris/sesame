module FileContents : sig
  type t = [ `Blob of string option ] [@@deriving yojson]
end

module Release : sig
  type r = { name : string; created_at : Ptime.t; url : Uri.t }
  [@@deriving yojson]

  type t = r option array array [@@deriving yojson]
end

module File : sig
  type t = string [@@deriving yojson]
end

module Files : sig
  type entry = { name : string } [@@deriving yojson]

  type t = entry array [@@deriving yojson]
end
