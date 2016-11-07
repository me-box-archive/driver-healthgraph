module type S = sig
    
  open Databox_directory_types_t
    
  type 'a response = ('a, Error.t) Result_lwt.t
  
  val register_vendor : vendor -> vendor response
  
  val get_datastore : hostname:string -> datastore response
  
  val register_driver : driver -> driver response 
  
  val register_sensor_type : sensor_type -> sensor_type response
  
  val register_sensor : sensor -> sensor response
  
end

val create : Uri.t -> (module Cohttp_lwt.Client) -> (module S) 
