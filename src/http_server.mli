module type S = sig
  
  val server : unit -> unit Lwt.t
  
end

val create : (module Config.S with type t = 'c) -> 'c -> (module S)
