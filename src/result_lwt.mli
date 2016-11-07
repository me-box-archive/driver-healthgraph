open Result
  
type ('ok, 'error) t = ('ok, 'error) result Lwt.t

val bind : ('ok, 'error) t -> ('ok -> ('b, 'error) t) -> ('b, 'error) t
  
val ( >>= ) : ('ok, 'error) t -> ('ok -> ('b, 'error) t) -> ('b, 'error) t
    
val return : 'ok -> ('ok, _) t
  
val fail : 'error -> (_, 'error) t
