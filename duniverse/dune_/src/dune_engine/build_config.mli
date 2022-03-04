(** Build system's configuration: how to generate rules, how to handle events,
    whether to use the shared cache, etc. *)

open! Stdune
open! Import
module Action_builder = Action_builder0

module Context_or_install : sig
  type t =
    | Install of Context_name.t
    | Context of Context_name.t

  val to_dyn : t -> Dyn.t
end

type extra_sub_directories_to_keep = Subdir_set.t

type gen_rules_result =
  | Rules of extra_sub_directories_to_keep * Rules.t
  | Unknown_context_or_install
  | Redirect_to_parent
      (** [Redirect_to_parent] means that the parent will generate the rules for
          this directory. *)

module type Rule_generator = sig
  (** The rule generator.

      This callback is used to generate the rules for a given directory in the
      corresponding build context. It receives the directory for which to
      generate the rules and the split part of the path after the build context.
      It must return an additional list of sub-directories to keep. This is in
      addition to the ones that are present in the source tree and the ones that
      already contain rules.

      [gen_rules] may only generate rules whose targets are descendant of [dir]. *)
  val gen_rules :
       Context_or_install.t
    -> dir:Path.Build.t
    -> string list
    -> gen_rules_result Memo.Build.t
end

type t = private
  { contexts : Build_context.t Context_name.Map.t Memo.Lazy.t
  ; rule_generator : (module Rule_generator)
  ; sandboxing_preference : Sandbox_mode.t list
  ; promote_source :
         chmod:(int -> int)
      -> delete_dst_if_it_is_a_directory:bool
      -> src:Path.Build.t
      -> dst:Path.Source.t
      -> Build_context.t option
      -> unit Fiber.t
  ; stats : Dune_stats.t option
  ; cache_config : Dune_cache.Config.t
  ; cache_debug_flags : Cache_debug_flags.t
  ; implicit_default_alias :
      Path.Build.t -> unit Action_builder.t option Memo.Build.t
  }

(** Initialise the build system. This must be called before running the build
    system and only once. *)
val set :
     stats:Dune_stats.t option
  -> contexts:Build_context.t list Memo.Lazy.t
  -> promote_source:
       (   chmod:(int -> int)
        -> delete_dst_if_it_is_a_directory:bool
        -> src:Path.Build.t
        -> dst:Path.Source.t
        -> Build_context.t option
        -> unit Fiber.t)
  -> cache_config:Dune_cache.Config.t
  -> cache_debug_flags:Cache_debug_flags.t
  -> sandboxing_preference:Sandbox_mode.t list
  -> rule_generator:(module Rule_generator)
  -> implicit_default_alias:
       (Path.Build.t -> unit Action_builder.t option Memo.Build.t)
  -> unit

val get : unit -> t
