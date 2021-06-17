module Builder : Current_cache.S.BUILDER

type t = { name : string; commit_id : Current_git.Commit_id.t; dir : string }
(** The result of cloning a repository passing through the [name], returning the
    commit id and most importantly the absolute path to the checked out
    repository *)

val v : name:string -> repo:string -> branch:string -> Fpath.t -> Builder.Key.t
(** [v ~name ~repo ~branch dir] generate a new builder key to pass to the
    {!clone} function *)

val clone :
  ?gref:string ->
  ?schedule:Current_cache.Schedule.t ->
  Builder.Key.t ->
  t Current.t
(** [clone key] will clone the repositoy specified by [key] into the directory
    also specified by [key], to access the data from the repository use the
    [dir] in the result of this function as it contains the path to the data. *)
