(** Implements universally unique identifiers based on version 3 of the UUID
    specification.  Identifier generation is thread safe, and fast.
*)

open! Core_kernel

(** When [am_running_test], [sexp_of_t] shows all zeros (the nil UUID). *)
type t [@@deriving hash, sexp_of]

include Identifiable.S with type t := t
include Invariant.S with type t := t
include Quickcheckable.S with type t := t

val t_of_sexp : Sexp.t -> t
[@@deprecated "[since 2017-11] Use a [Stable] or [Unstable] [t_of_sexp]."]

val create : unit -> t
[@@deprecated "[since 2018-10] Use [Uuid.create_random] or [Uuid_unix.create]"]

val create_random : Random.State.t -> t

(** [to_string_hum t] is like [to_string], except when [am_running_test], in
    which case it shows all zeros (the nil UUID). *)
val to_string_hum : t -> string

val arg_type : t Command.Arg_type.t

module Unstable : sig
  (** Unlike [Stable] deserializers, [Unstable.t_of_sexp] validates the input. *)
  type nonrec t = t [@@deriving bin_io, compare, hash, sexp]
end

module Stable : sig
  module V1 : sig
    type nonrec t = t [@@deriving hash]

    include
      Stable_comparable.V1
      with type t := t
      with type comparator_witness = comparator_witness

    val for_testing : t
  end
end

(**/**)

(*_ See the Jane Street Style Guide for an explanation of [Private] submodules:

  https://opensource.janestreet.com/standards/#private-submodules *)
module Private : sig
  val is_valid_exn : t -> unit
  val nil : t
  val create : hostname:string -> pid:int -> t
  val bottom_4_bits_to_hex_char : int -> char
end
