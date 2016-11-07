module type S = sig
    
  open Databox_directory_types_t
    
  type 'a response = ('a, Error.t) Result_lwt.t
  
  val register_vendor : vendor -> vendor response
  
  val get_datastore : hostname:string -> datastore response
  
  val register_driver : driver -> driver response 
  
  val register_sensor_type : sensor_type -> sensor_type response
  
  val register_sensor : sensor -> sensor response
  
end

module type Server_uri = sig
  
  val v : Uri.t
   
end

module Make
    (Server_uri : Server_uri) 
    (Cohttp_client : Cohttp_lwt.Client) : S = struct

  type 'a response = ('a, Error.t) Result_lwt.t
  
  module R = Result_lwt
  module Json = Databox_directory_types_j
  
  open Databox_directory_types_t
  
  let create_uri path =
    let uri = Server_uri.v in
    let prefix = Uri.path uri in
    match prefix with
    | "" -> Uri.with_path uri path
    | _ ->
      match prefix.[(String.length prefix) - 1], path.[0] with
      | '/', '/' -> 
        let suffix = String.sub path 1 (String.length path - 1) in
        Uri.with_path uri (prefix ^ suffix)
      | '/', _ -> Uri.with_path uri (prefix ^ path)
      | _, '/' -> Uri.with_path uri (prefix ^ path)
      | _, _ -> Uri.with_path uri (prefix ^ "/" ^ path)

  let stream_of_string s =
    let remaining = ref s in
    let chunk = 100 in
    Lwt_stream.from (fun () ->
      match String.length !remaining with
      | 0 -> Lwt.return_none
      | i when i >= chunk ->
        let res = String.sub !remaining 0 chunk in
        remaining := String.sub !remaining chunk 
            (String.length !remaining - chunk);
        Lwt.return_some res
      | i -> 
        let res = String.sub !remaining 0 (String.length !remaining) in
        remaining := "";
        Lwt.return_some res)
  
  let do_post path json conv = 
    let (>>=) = Lwt.(>>=) in
    let uri = create_uri path in
    let headers = Cohttp.Header.init_with "content-type" "application/json" in
    let body = json |> stream_of_string |> Cohttp_lwt_body.of_stream
    in
    try%lwt
      Cohttp_client.post ~body ~headers uri >>= fun (response, body) ->
        Cohttp_lwt_body.to_string body >>= fun body ->
        conv body |> R.return
    with _ ->
      print_endline "Error :("; 
      R.fail `Unknown_error
    
  let register_vendor vendor =
    let path = "/vendor/register" in
    let json = Json.string_of_vendor vendor in 
    let conv = Json.vendor_of_string in
    do_post path json conv
    
  let get_datastore ~hostname =
    let path = "/datastore/get_id" in
    let json = `Assoc ([
      ("hostname", `String (hostname))
    ]) |> Yojson.Safe.to_string in
    let conv = Json.datastore_of_string in
    do_post path json conv

  let register_driver (driver : driver) =
    let path = "/driver/register" in
    let json = `Assoc ([
      ("description", `String (driver.description));
      ("hostname", `String (driver.hostname));
      ("vendor_id", `Int (match driver.vendor with 
          | None -> -1 
          | Some v -> match v.id with None -> -1 | Some id -> id));
    ]) |> Yojson.Safe.to_string in
    let conv = (fun v -> { (Json.driver_of_string v) 
        with vendor = driver.vendor }) 
    in
    do_post path json conv

  let register_sensor_type sensor_type =
    let path = "/sensor_type/register" in
    let json = Json.string_of_sensor_type sensor_type in
    let conv = Json.sensor_type_of_string in
    do_post path json conv
  
  let register_sensor sensor =
    let path = "/sensor/register" in
    let json = `Assoc ([
      ("vendor_id", `Int (match sensor.vendor with 
          | None -> -1 
          | Some v -> match v.id with None -> -1 | Some id -> id));
      ("datastore_id", `Int (match sensor.datastore with 
          | None -> -1 
          | Some v -> match v.id with None -> -1 | Some id -> id));
      ("driver_id", `Int (match sensor.driver with 
          | None -> -1 
          | Some v -> match v.id with None -> -1 | Some id -> id));
      ("sensor_type_id", `Int (match sensor.sensor_type with 
          | None -> -1 
          | Some v -> match v.id with None -> -1 | Some id -> id));
      ("vendor_sensor_id", `String (sensor.vendor_sensor_id));
      ("unit", `String (sensor.units));
      ("short_unit", `String (sensor.short_units));
      ("description", `String (sensor.description));
      ("location", `String (sensor.location));
    ]) |> Yojson.Safe.to_string in
    let conv = (fun v -> { (Json.sensor_of_string v) 
        with vendor = sensor.vendor;
        datastore = sensor.datastore;
        driver = sensor.driver;
        sensor_type = sensor.sensor_type  }) 
    in
    do_post path json conv

end

let create server_uri (module Client : Cohttp_lwt.Client) =
  (module Make (struct let v = server_uri end) (Client) : S)
