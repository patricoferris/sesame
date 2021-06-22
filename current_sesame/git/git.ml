module type With_fs = Sesame.Types.S with type Input.t = Fpath.t

module Make (FS : With_fs) = struct
  module Builder = struct
    type t = No_context

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

    let build No_context job repo = Current_git.with_checkout ~job repo FS.build
  end

  module GC = Current_cache.Make (Builder)

  let get ?schedule repo =
    let open Current.Syntax in
    Current.component "build with repo"
    |> let> repo = repo in
       GC.get ?schedule No_context repo
end
