module type With_fs = Sesame.Types.S with type Input.t = Fpath.t

module Make (FS : With_fs) = struct
  module Builder = struct
    type t = No_context

    let auto_cancel = true

    let id = "current-sesame.git"

    module Key = struct
      type t = Current_git.Commit.t * Fpath.t option

      let digest (c, f) =
        Fmt.str "%s-%a" (Current_git.Commit.marshal c) Fmt.(option Fpath.pp) f
    end

    let pp ppf (_, f) =
      Fmt.pf ppf "checkout with path %a" (Fmt.option Fpath.pp) f

    module Value = struct
      type t = FS.Output.t

      let marshal = FS.Output.encode

      let unmarshal = FS.Output.decode
    end

    let build No_context job (repo, rest) =
      let open Lwt.Infix in
      Current.Job.start job ~level:Current.Level.Harmless >>= fun () ->
      Current_git.with_checkout ~job repo (fun path ->
          match rest with
          | None -> FS.build path
          | Some rest -> FS.build Fpath.(path // rest))
  end

  module GC = Current_cache.Make (Builder)

  let get ?schedule ?(label = "build with repo") path repo =
    let open Current.Syntax in
    Current.component "%s" label
    |> let> repo = repo in
       GC.get ?schedule No_context (repo, path)
end
