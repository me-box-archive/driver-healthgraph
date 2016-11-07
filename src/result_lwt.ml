open Result
  
type ('ok, 'error) t = ('ok, 'error) result Lwt.t

let bind res f =
  match%lwt res with
  | Ok x -> f x
  | Error e -> Error(e) |> Lwt.return

let ( >>= ) = bind
    
let return x = Ok(x) |> Lwt.return
  
let fail e = Error(e) |> Lwt.return
