module type With_fs = Sesame.Types.S with type Input.t = Fpath.t

module Make (FS : With_fs) = struct
  module Builder = struct
    type t = Fpath.t -> Fpath.t

    let auto_cancel = true

    let pp = Current_git.Commit.pp

    let id = "current-sesame.git"

    module Key = struct
      type t = Current_git.Commit.t

      let digest = Current_git.Commit.marshal
    end

    module Value = struct
      type t = FS.Output.t

      let marshal = FS.Output.encode

      let unmarshal = FS.Output.decode
    end

    let build f job repo =
      let open Lwt.Infix in
      Current.Job.start job ~level:Current.Level.Harmless >>= fun () ->
      Current_git.with_checkout ~job repo (fun path -> FS.build (f path))
  end

  module GC = Current_cache.Make (Builder)

  let get ?schedule ?(label = "build with repo") f repo =
    let open Current.Syntax in
    Current.component "%s" label
    |> let> repo = repo in
       GC.get ?schedule f repo
end
