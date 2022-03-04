type t = Linux | Windows | Mac

val os : t

val fd_of_int: int -> Unix.file_descr
