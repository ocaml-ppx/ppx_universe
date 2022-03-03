#!/bin/bash
set -e

# allow packages in the work space that don't directly build with dune, but have a dune port in the dune-universe
opam repo add dune-universe git+https://github.com/dune-universe/opam-overlays.git

# on pitag-ha's fork, there's also an opam-overlay for stdcompat. if we didn't add that, we'd discard 4 reverse dependencies that depend on stdcompat
opam repo add dune-universe-pitag git+https://github.com/pitag-ha/opam-overlays.git

opam update
# pin to an old opam-monorepo since the last version has a bug
opam pin add opam-monorepo https://github.com/ocamllabs/opam-monorepo.git#8054037deccc8b50e3e0755a0bbf4976f2360aab -y

# pin ppxlib to the current branch giving it version 0.24.0.
# if not, opam-monorepo will give it the place-holder version zdev and run into resolver conflicts for packages explicitly requiring ppxlib <= 0.24.0
opam pin ppxlib.0.24.0 .

# install the sqlite3 library, since `hack_parallel` depends on `conf-sqlite3`
sudo apt install libsqlite3-dev

# clone all reverse dependencies into `rev-deps/` and add them to `rev-deps/.deps`; both janestreet and non-janestreet reverse dependencies
./dev/helpers.sh pull janestreet
./dev/helpers.sh pull

# two projects have ended up in dev/.do_manually.txt and need to be added manually: ppx_deriving_encoding and ppx_deriving_jsoo
# for ppx_deriving_encoding, don't add it to the workspace and remove it from rev-deps/.deps instead: trying to compile it throws an "Exception: Failure "version [unspecified] not understood"
sed -i '/ppx_deriving_encoding/d' rev-deps/.deps
# for ppx_deriving_jsoo, add it to the workspace
cd rev-deps/ &&
git submodule add https://gitlab.com/o-labs/ppx_deriving_jsoo &&
cd ..

# re-add ppx_sexp_message without checking it out to the last release branch: seems like the git history on that repo has been messed up and now the release tags point to commits that don't exist anymore
git submodule deinit -f -- rev-deps/ppx_sexp_message
rm -rf .git/modules/rev-deps/ppx_sexp_message
git rm -f rev-deps/ppx_sexp_message
cd rev-deps &&
git submodule add https://github.com/janestreet/ppx_sexp_message.git ppx_sexp_message &&
cd ..


# remove different copies of the same multi-package repos
git submodule deinit -f -- rev-deps/js_of_ocaml-*
rm -rf .git/modules/rev-deps/js_of_ocaml-*
git rm -f rev-deps/js_of_ocaml-*
git submodule deinit -f -- rev-deps/repr-fuzz
rm -rf .git/modules/rev-deps/repr-fuzz
git rm -f rev-deps/repr-fuzz
git submodule deinit -f -- rev-deps/tyxml-jsx
rm -rf .git/modules/rev-deps/tyxml-jsx
git rm -f rev-deps/tyxml-jsx
git submodule deinit -f -- rev-deps/tyxml-syntax
rm -rf .git/modules/rev-deps/tyxml-syntax
git rm -f rev-deps/tyxml-syntax

# remove the rev-deps that don't fulfil the standards for the ppx-universe
sed -i '/scaml/d' rev-deps/.deps # has a strict =0.13.0 constraint for ppxlib and so depends on OMP1
sed -i '/ppx_seq/d' rev-deps/.deps # doesn't have an opam file
sed -i '/ppx_show/d' rev-deps/.deps # doesn't have an opam file
sed -i '/clangml/d' rev-deps/.deps # doesn't have an opam file
sed -i '/repr-fuzz/d' rev-deps/.deps # (recursively) depends on afl-persistent, which doesn't build with dune and isn't on opam-overlays
sed -i '/ppx_deriving\./d' rev-deps/.deps # (recursively) depends on afl-persistent, which doesn't build with dune and isn't on opam-overlays
sed -i '/pgocaml_ppx/d' rev-deps/.deps # (recursively) depends on calendar, which doesn't build with dune and isn't on opam-overlays
sed -i '/ppx_rapper/d' rev-deps/.deps # (recursively) depends on calendar, which doesn't build with dune and isn't on opam-overlays
sed -i '/ego/d' rev-deps/.deps # (recursively) depends on ocamldot, which doesn't build with dune and isn't on opam-overlays
sed -i '/nuscr/d' rev-deps/.deps # (recursively) depends on process, which doesn't build with dune and isn't on opam-overlays
sed -i '/xtmpl_ppx/d' rev-deps/.deps # (recursively) depends on process, which doesn't build with dune and isn't on opam-overlays
sed -i '/spoc_ppx/d' rev-deps/.deps # (recursively) depends on camlp4, which doesn't build with dune and isn't on opam-overlays
sed -i '/GT/d' rev-deps/.deps # (recursively) depends on logger-p5, which doesn't build with dune and isn't on opam-overlays
sed -i '/rdf_ppx/d' rev-deps/.deps # (recursively) depends on uucp >= 4.14.0, which doesn't build with dune. opam-overlays only has uucp.4.13.0
sed -i '/ppx_deriving_popper/d' rev-deps/.deps # (recursively) depends on pringo, which doesn't build with dune and isn't on opam-overlays
sed -i '/metapp/d' rev-deps/.deps # (recursively) depends on stdcompat, which doesn't doesnt' declare dune in it's opam file and isn't on opam-overlays. Tried adding stdcompat to opam-overlays, but that isn't straight-forward (dune complains about it having a public_name)
sed -i '/metaquot/d' rev-deps/.deps # (recursively) depends on stdcompat, which doesn't doesnt' declare dune in it's opam file and isn't on opam-overlays. Tried adding stdcompat to opam-overlays, but that isn't straight-forward (dune complains about it having a public_name)
sed -i '/override/d' rev-deps/.deps # (recursively) depends on stdcompat, which doesn't doesnt' declare dune in it's opam file and isn't on opam-overlays. Tried adding stdcompat to opam-overlays, but that isn't straight-forward (dune complains about it having a public_name)
sed -i '/ppx_inline_alcotest/d' rev-deps/.deps # (recursively) depends on stdcompat, which doesn't doesnt' declare dune in it's opam file and isn't on opam-overlays. Tried adding stdcompat to opam-overlays, but that isn't straight-forward (dune complains about it having a public_name)
sed -i '/pla/d' rev-deps/.deps # (recursively) depends on stdcompat, which doesn't doesnt' declare dune in it's opam file and isn't on opam-overlays. Tried adding stdcompat to opam-overlays, but that isn't straight-forward (dune complains about it having a public_name)
sed -i '/js_of_ocaml-compiler/d' rev-deps/.deps # doesn't compile with ocaml.4.14.0

# check out a branch of ppxx that depends on ppxlib and has a ppxx.opam file. It's default branch doesn't have an opam file.
cd rev-deps/ppxx/ &&
git checkout master &&
cd ../..

# remove spoc_ppx: having it in the work space messes with dune since it has an empty opam file in addition to the correct opam file and anyways, it's already removed from rev-deps/.deps and hence won't be compiled
git submodule deinit -f -- rev-deps/spoc_ppx
rm -rf .git/modules/rev-deps/spoc_ppx
git rm -f rev-deps/spoc_ppx

# checkout gospel to the commit before updating to cmdliner.1.1.0
cd rev-deps/gospel &&
git checkout bd54a5199a7f04dab149036eb9073f7b53b979fd &&
cd ../..

# Remove the ppxlib constraint "<= 0.24" in OCanren-ppx: we've forced opam-monorepo to consider the ppxlib version to be 0.24.0 and opam's ordering consideres 0.24 strictly smaller than 0.24.0
# cd rev-deps/OCanren-ppx &&
# sed -i "s/>= \"0.22\" \& <= \"0.24\"/>= \"0.22\" \& < \"0.25.0\"/g" OCanren-ppx.opam
# # Manually: same in dune-project
# git add OCanren-ppx.opam
# git commit -m "Remove ppxlib constraint for workspace creation"
# cd ../..

# pull in the dependencies of the reverse dependencies
./dev/helpers.sh install-deps

# remove duplicates that are both in `rev-deps/` and `duniverse/` due to multi-package structures
rm -rf duniverse/bitstring/ duniverse/gen_js_api/ duniverse/js_of_ocaml/ duniverse/landmarks/ duniverse/lwt/ duniverse/ocaml-cstruct/ duniverse/ocf/ duniverse/ppx_deriving/ duniverse/ppx_deriving_yojson/ duniverse/repr/ duniverse/tyxml/ duniverse/wtr/ duniverse/camlrack duniverse/ocaml-rpc duniverse/metapp duniverse/metaquot 

# some things to do manually:
# 1. add `(modules_without_implementation clangml_config)` to rev-deps/clangml/config/dune
# 2. remove uchar from rev-deps/sedlex/src/lib/dune
# 3. remove uchar from rev-deps/js_of_ocaml/lib/js_of_ocaml/dune
# 4. remove `(public_name stdcompat)` from duniverse/stdcompat/dune
# commit all those changes and push them to a remote to be available when cloning the submodule structure

# work around a ctypes bug
rm -rf duniverse/ocaml-ctypes/ duniverse/ocaml-integers/ duniverse/bigarray-compat/ duniverse/stdlib-shims/
opam install ctypes-foreign -y
