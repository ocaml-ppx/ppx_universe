module Refl = Desc

type unit__structure =
  [`Name of [`Constr of ([`Constructor of ([`Tuple of unit] * unit)] ref)]]

type unit__arity = [`Zero]

type unit__rec_group = (unit__arity * unit__structure) * unit

type _ Refl.refl += Name_unit : unit Refl.refl

type unit__kinds = [`Constr | `Name]

type unit__gadt = unit

let unit_refl :
    (unit, unit__structure, 'arity, unit__rec_group, [> unit__kinds],
      unit, unit, unit, unit) Refl.desc =
  Name {
    refl = Name_unit;
    name = "unit";
    desc = Constr {
    constructors = CLeaf (
        Constructor {
          name = "()";
          kind = CTuple TNil;
          eqs = ENil;
          attributes = Tools.attributes_empty; });
    construct = (fun (Refl.CEnd ((), ())) -> ());
    destruct = (fun () -> CEnd ((), ()));
  }}

type 'a list = 'a Stdcompat.List.t =
  | []
  | (::) of 'a * 'a list
        [@@deriving refl]

type ('a, 'b) result = ('a, 'b) Stdcompat.Stdlib.result =
  | Ok of 'a
  | Error of 'b
        [@@deriving refl]

type 'a option = 'a Stdcompat.Option.t =
  | None
  | Some of 'a
        [@@deriving refl]

type 'a ref = 'a Stdcompat.Stdlib.ref =
  { mutable contents : 'a }
        [@@deriving refl]
