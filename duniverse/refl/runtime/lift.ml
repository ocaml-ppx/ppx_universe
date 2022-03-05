open Desc

open Tools

module Make (Target : Metapp.ValueS) = struct
  module Lifter = struct
    type 'a t = 'a -> Target.t
  end

  module Lifters = Vector (Lifter)

  type 'a hook_fun = 'a refl -> (?hook : hook -> 'a Lifter.t) -> 'a Lifter.t
  and hook = { hook : 'a . 'a hook_fun }

  let rec lift :
    type a structure arity rec_group positive negative direct gadt .
    ?hook : hook ->
    (a, structure, arity, rec_group, [< Kinds.liftable], positive, negative,
      direct, gadt) desc -> (arity, direct) Lifters.t -> a Lifter.t =
  fun ?hook desc lifters x ->
    let lift_tuple lifters tuple =
      let lift_tuple_item (Tuple.Fold { desc; value; _ }) accu =
        lift ?hook desc lifters value :: accu in
      let accu = Tuple.fold lift_tuple_item tuple [] in
      Target.tuple (List.rev accu) in

    let lift_record lifters record =
      let lift_record_field (Record.Fold { field; value; _ }) accu =
        let (label, value) =
          match field with
          | Mono { label; desc; _ } ->
              (label, lift ?hook desc lifters value) in
        (Longident.Lident label, value) :: accu in
      let accu = Record.fold lift_record_field record [] in
      Target.record accu in

    match desc with
    | Variable index -> Lifters.get index lifters x
    | Builtin Bool -> Target.of_bool x
    | Builtin Bytes -> Target.of_bytes x
    | Builtin Char -> Target.of_char x
    | Builtin Float -> Target.of_float x
    | Builtin Int -> Target.of_int x
    | Builtin Int32 -> Target.of_int32 x
    | Builtin Int64 -> Target.of_int64 x
    | Builtin Nativeint -> Target.of_nativeint x
    | Builtin String -> Target.of_string x
    | Array desc ->
        Target.array (Array.to_list (Array.map (lift ?hook desc lifters) x))
    | Constr { constructors; destruct; _ } ->
        let Constructor.Destruct destruct =
          Constructor.destruct constructors (destruct x) in
        let lifters' =
          match destruct.link with
          | Constructor.Exists
              { presence = Absent; exists_count; exists; variables; _ } ->
              lifters |>
              Lifters.append None
                variables.presences variables.direct_count variables.direct
                exists_count exists
          | Constructor.Constructor -> lifters in
        let arg =
          let open Tuple in
          match destruct.kind with
          | Constructor.Tuple { structure = []; _ } -> None
          | Constructor.Tuple tuple -> Some (lift_tuple lifters' tuple)
          | Constructor.Record record -> Some (lift_record lifters' record) in
        Target.force_construct
          (Metapp.mkloc (Longident.Lident destruct.name)) arg
    | Variant { constructors; destruct; _ } ->
        let Variant.Destruct destruct =
          Variant.destruct constructors (destruct x) in
        begin match destruct.kind with
        | Variant.Constructor { name; argument } ->
            let arg =
              match argument with
              | Variant.None -> None
              | Variant.Some { desc; value } ->
                  Some (lift ?hook desc lifters value) in
            Target.variant name arg
        | Variant.Inherit { desc; value } ->
            lift ?hook desc lifters value
        end
    | Tuple { structure; destruct; _ } ->
        lift_tuple lifters
          { structure = Tuple.of_desc structure; values = destruct x }
    | Record { structure; destruct; _ } ->
        lift_record lifters { structure; values = destruct x }
    | Lazy desc ->
        Target.lazy_ (lift ?hook desc lifters (Lazy.force x))
    | Apply { arguments; desc; transfer } ->
        let lifters =
          Lifters.make { f = fun x -> lift ?hook x }
            arguments transfer lifters in
        lift ?hook desc lifters x
    | Rec { desc; _ } ->
        lift ?hook desc lifters x
    | RecGroup { desc } ->
        lift ?hook desc lifters x
    | SelectGADT { desc; _ } ->
        lift ?hook desc lifters x
    | SubGADT { desc; _ } ->
        lift ?hook desc lifters x
    | Attributes { desc; _ } ->
        lift ?hook desc lifters x
    | Name { refl; desc; _ } ->
        begin match hook with
        | None -> lift desc lifters x
        | Some hook ->
            hook.hook refl (fun ?(hook = hook) -> lift ~hook desc lifters) x
        end
    | MapOpaque _ ->
        Target.extension (Metapp.mkloc "opaque", PStr [])
    | Opaque _ ->
        Target.extension (Metapp.mkloc "opaque", PStr [])
    | Arrow _ ->
        Target.extension (Metapp.mkloc "arrow", PStr [])
    | LabelledArrow _ ->
        Target.extension (Metapp.mkloc "arrow", PStr [])
    | Object _ ->
        Target.extension (Metapp.mkloc "object", PStr [])
    | _ -> .
end

module Exp = Make (Metapp.Exp)

module Pat = Make (Metapp.Pat)
