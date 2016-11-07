let vendor_name = "Runkeeper";;
let driver_name = "Healthgraph";;
let driver_description = "Databox driver for the Runkeeper Healthgraph API.";;
let datastore_name = "datastore-timeseries";;
let sensors = Databox_directory_types_t.([
  ({ id = None; description = "activity" }, [
    {
      id = None;
      vendor = None;
      datastore = None;
      driver = None;
      sensor_type = None;
      vendor_sensor_id = "activity";
      units = "";
      short_units = "";
      description = "An activity";
      location = "In the cloud";  
    }
  ]);
]);;

Logs.set_level (Some Logs.Info);;
Logs.set_reporter (Logs.format_reporter ());;

let register () =
  Logs.info (fun m -> m "Registering with the Databox Directory");
  let directory_endpoint = Sys.getenv "DATABOX_DIRECTORY_ENDPOINT" in
  Logs.info (fun m -> 
      m "Using Databox Directory Endpoint: %s" directory_endpoint);
  
  let module Dir =
    (val Databox_directory_client.create (Uri.of_string directory_endpoint)
        (module Cohttp_lwt_unix.Client : Cohttp_lwt.Client) 
        : Databox_directory_client.S)
  in
  
  let open Result_lwt in
  let open Databox_directory_types_t in
  
  let pp_id = function 
    | None -> "None"
    | Some id -> string_of_int id
  in 
  
  Logs.info (fun m -> m "Attempting to register vendor");
  Dir.register_vendor { id = None; description = vendor_name } 
  >>= fun vendor ->
    Logs.info (fun m -> m "Registered vendor with ID: %s" (pp_id vendor.id));
    Logs.info (fun m -> m "Attempting to fetch '%s' datastore" datastore_name);
    Dir.get_datastore "datastore-timeseries" 
  >>= fun datastore ->
    Logs.info (fun m -> m "Fetched datastore with ID: %s" (pp_id datastore.id));
    let driver = {
      id = None;
      hostname = driver_name;
      description = driver_description;
      vendor = Some (vendor);
    } in
    Logs.info (fun m -> m "Attempting to register driver");
    Dir.register_driver driver
  >>= fun driver ->
    Logs.info (fun m -> m "Registered driver with ID: %s" (pp_id driver.id));
    
    let rec reg_st acc = function
      | (st, ss)::tail -> 
        Logs.info (fun m -> m 
            "Attempting to register sensor type '%s'" 
            ((st : sensor_type).description));
        Dir.register_sensor_type st >>= fun st ->
        Logs.info (fun m -> m "Registered sensor type with ID: %s" 
            (pp_id st.id));
        let rec reg_s acc = function
          | s::tail -> 
            Logs.info (fun m -> m "Attempting to register sensor '%s'"
                s.description);
            let sensor = {
              s with
              vendor = Some vendor;
              datastore = Some datastore;
              driver = Some driver;
              sensor_type = Some st;  
            } in 
            Dir.register_sensor sensor >>= fun sensor ->
            Logs.info (fun m -> m "Registered sensor with ID: %s" 
                (pp_id sensor.id));
            reg_s ({
              sensor with
              vendor = Some vendor;
              datastore = Some datastore;
              driver = Some driver;
              sensor_type = Some st;  
            }::acc) tail
          | [] -> return acc
        in
        reg_s [] ss >>= fun ss -> 
        reg_st ((st, ss)::acc) tail
      | [] -> return acc
    in
    reg_st [] sensors
  >>= fun sensors ->
    return (vendor, datastore, driver, sensors)
    
let () =
  Logs.info (fun m -> m "healthgraph-databox-driver");
  let open Lwt in
  let module C = Config.File in
  let config = C.init "config.txt" in
  let module Server = (val Http_server.create 
    (module C : Config.S with type t = C.t) config) 
  in
  (register ()) >>= (fun _ -> return_unit) <?> 
    Server.server () |> Lwt_main.run
