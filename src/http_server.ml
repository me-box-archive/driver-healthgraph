module type S = sig
  
  val server : unit -> unit Lwt.t
  
end

module type Config_impl = sig
  
  module Config : Config.S
  
  val config : Config.t
  
end

module Make (Config : Config.S) (Ci : Config_impl with module Config = Config) 
    : S = struct

  open Lwt
  open Cohttp
  open Cohttp_lwt_unix
  
  let hdr_ct_utf8 = ("Content-Type", "text/html; charset=utf-8")
  let hdr_js = ("Content-Type", "application/javascript")
  let hdr_json = ("Content-Type", "application/json")
  
  type response =
    | Template of (string * string) list * string
    | Redirect of Uri.t
  
  let render renderer lookup =
    let buf = Buffer.create 0 in
    let ppf = Format.formatter_of_buffer buf in
    renderer ppf lookup;
    Buffer.contents buf
    
  let index req body = 
    let output = match Config.get_access_token Ci.config with
    | Some _ -> render Tpl_index_authorised.render (fun _ -> "")
    | None -> 
      let uri = Request.uri req in
      let scheme = match Uri.scheme uri with
        | Some s -> s
        | None -> "http"
      in
      let origin_uri = Uri.make ~scheme:scheme
        ?userinfo:(Uri.userinfo uri) ?host:(Uri.host uri)
        ?port:(Uri.port uri) ~path:"/authorisation.html" ()
        |> Uri.to_string
      in 
      let 
        oauth_intermediary_uri = Config.get_oauth_intermediary_uri Ci.config 
      in
      let auth_uri = Uri.with_query oauth_intermediary_uri
        [("start", ["start"]); ("origin_uri", [origin_uri])] 
        |> Uri.to_string
      in
      let lookup = function
        | "auth_uri" -> auth_uri
        | "origin_uri" -> origin_uri
        | "oauth_intermediary_uri" -> oauth_intermediary_uri |> Uri.to_string
        | _ -> ""
      in
      render Tpl_index_unauthorised.render lookup
    in
    Template([hdr_ct_utf8], output)
    
  let authorisation req body =
    let uri = Request.uri req in
    let render_fail () = 
      Template([hdr_ct_utf8], 
        render Tpl_authorisation_failed.render (fun _ -> ""))
    in 
    match Uri.get_query_param uri "data" with
    | None -> render_fail ()
    | Some data ->
      let module J = Yojson.Safe in
      try
        match J.from_string data with
        | `Assoc o -> 
          (match List.assoc "access_token" o with
          | `String at ->
            Config.set_access_token Ci.config at;
            Redirect(Uri.with_path (Uri.with_query uri []) "/index.html")
          | _ -> render_fail ())
        | _ -> render_fail ()
      with _ -> render_fail ()
      
  let update_config req body =
    Lwt.bind (Cohttp_lwt_body.to_string body) (fun body -> 
      let uri = Uri.empty in
      let query = Uri.query_of_encoded body in
      let uri = Uri.with_query uri query in
      (match Uri.get_query_param uri "oauth_intermediary_uri" with
      | Some uri -> 
        Config.set_oauth_intermediary_uri Ci.config (Uri.of_string uri)
      | None -> ());
      Lwt.return_unit) |> ignore; 
    Template([hdr_json], "")
    
  let paths = [
    ("/index.html", index);
    ("/", index);
    ("/authorisation.html", authorisation);
    ("/jquery.js", fun _ _ -> 
        Template([hdr_js], render Tpl_jquery.render (fun _ -> "")));
    ("/uri.js", fun _ _ -> 
        Template([hdr_js], render Tpl_uri.render (fun _ -> "")));
    ("/update-config", update_config);
  ] 
  
  let server =
    let headers = Header.init_with "Access-Control-Allow-Origin" "*" in
    let callback _conn req body =
      let path = req |> Request.uri |> Uri.path in
      try
        List.assoc path paths |> (fun r -> 
          match r req body with
          | Template (hdrs, response) -> 
            let headers = Header.add_list headers hdrs in
            Server.respond_string ~headers ~status:`OK ~body:response ()
          | Redirect uri ->
            Server.respond_redirect ~uri ()
        )
      with Not_found -> 
        Server.respond_error ~headers ~status:`Not_found ~body:"Not found" ()
    in
    fun () -> Server.create ~mode:(`TCP (`Port 8080)) (Server.make ~callback ())

end

let create (type c) (module Config : Config.S with type t = c) config = 
  let module Ci : Config_impl with module Config = Config = struct
    module Config = Config
    let config = config
  end in
  (module Make (Config) (Ci) : S)
