module type S = sig
  
  type t
  
  val get_access_token : t -> string option
  
  val set_access_token : t -> string -> unit
  
  val get_oauth_intermediary_uri : t -> Uri.t
  
  val set_oauth_intermediary_uri : t -> Uri.t -> unit
  
end

module File = struct
  
  module CF = Config_file
  
  type t = {
    group : CF.group;
    path : string;
    access_token : string CF.option_cp;
    oauth_intermediary_uri : Uri.t CF.cp_custom_type;
  }
  
  let uri_wrappers = CF.({
    to_raw = (fun uri -> Raw.String(Uri.to_string uri));
    of_raw = function
      | Raw.String str -> Uri.of_string str
      | _ -> raise (Wrong_type(fun _ -> ()));
  })
    
  let init path =
    let g = new CF.group in
    let at = new CF.option_cp CF.string_wrappers ~group:g 
      ["access_token"] None ""
    in
    let oiu = new CF.cp_custom_type uri_wrappers ~group:g 
      ["oauth_intermediary_uri"] 
      (Uri.of_string "https://tsafe-oauth.wp.horizon.ac.uk/healthgraph/") "" 
    in
    g#read path;
    { 
      group = g;
      path = path;
      access_token = at;
      oauth_intermediary_uri = oiu;
    }
   
  let get_access_token c = 
    c.access_token#get
    
  let set_access_token c v =
    c.access_token#set (Some(v));
    c.group#write c.path
    
  let get_oauth_intermediary_uri c =
    c.oauth_intermediary_uri#get
    
  let set_oauth_intermediary_uri c v =
    c.oauth_intermediary_uri#set v;
    c.group#write c.path
  
end

