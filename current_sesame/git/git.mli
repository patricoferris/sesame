module type With_fs = Sesame.Types.S with type Input.t = Fpath.t

module Make (FS : With_fs) : sig
  val get :
    ?schedule:Current_cache.Schedule.t ->
    Current_git.Commit.t Current.t ->
    FS.t Current.t
  (** [get repo] will attempt to build from the locally cloned repository *)
end
