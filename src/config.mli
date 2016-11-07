module type S = sig
  
  type t
  
  val get_access_token : t -> string option
  
  val set_access_token : t -> string -> unit
  
  val get_oauth_intermediary_uri : t -> Uri.t
  
  val set_oauth_intermediary_uri : t -> Uri.t -> unit
    
end

module File : sig
  
  type t
  
  val init : string -> t
  
  include S with type t := t
  
end

