#!/bin/bash
set -e

github-remote-add() {
    origin=$(git config --get remote.origin.url)
    echo "git remote add $1 git@github.com:$1/${origin##*/}"
    git remote add $1 git@github.com:$1/${origin##*/}
}

# allow packages in the work space that don't directly build with dune, but have a dune port in the dune-universe
opam repo add dune-universe git+https://github.com/dune-universe/opam-overlays.git

opam update

# clone all reverse dependencies into `dunireverse/` and add them to `dunireverse/.deps`; both janestreet and non-janestreet reverse dependencies
./dev/rev-deps.sh pull janestreet
./dev/rev-deps.sh pull

# fix mlt_parser: they haven't merged the patch for the 0.11.0 bump yet
cd dunireverse/mlt_parser/ &&
github-remote-add NathanReb &&
git fetch --all &&
git checkout upgrade-ppxlib-0.18.0 &&
cd ../..

# also fix base_quickcheck and ppx_typerep_conv:
# their versions containing the 0.12.0 AST bump patches are already released on github, but not on opam yet
cd dunireverse/base_quickcheck/ && git checkout v0.14.1 && cd ../..
cd dunireverse/ppx_typerep_conv/ && git checkout v0.14.2 && cd ../..

# remove different copies of the same multi-package repos
git submodule deinit -f -- dunireverse/js_of_ocaml-*
rm -rf .git/modules/dunireverse/js_of_ocaml-*
git rm -f dunireverse/js_of_ocaml-*
git submodule deinit -f -- dunireverse/repr-fuzz
rm -rf .git/modules/dunireverse/repr-fuzz
git rm -f dunireverse/repr-fuzz

# clone 3 packages manually. git throws an error when trying to do so via the script
cd dunireverse/
git submodule add https://gitlab.com/o-labs/ppx_deriving_jsoo.git
git submodule add https://gitlab.com/o-labs/ppx_deriving_encoding.git
git submodule add git@github.com:JetBrains-Research/OCanren.git
cd OCanren/ && git checkout origin/dune && cd ..
cd ..
# to be done manually: check if there are more packages in `add_manually.txt` than those 3 and add them manually, if any
# same for `checkout_manually.txt`

# remove the rev-deps that already didn't fulfil the standard when preparing the 0.12.0 AST bump release
sed -i '/gen_js_ap/d' dunireverse/.deps
sed -i '/scaml/d' dunireverse/.deps
sed -i '/elpi/d' dunireverse/.deps
sed -i '/ppx_show/d' dunireverse/.deps
sed -i '/repr/d' dunireverse/.deps

# also remove a new rev-dep that doesn't fulfil the standard: it depends on stdcompat which doesn't build with dune
sed -i '/metapp/d' dunireverse/.deps

# use the same version among all packages of the multi-package project js_of_ocaml
sed -i 's/js_of_ocaml-compiler.3.9.1/js_of_ocaml-compiler.3.9.0/' dunireverse/.deps

# manually add accessor: ppx_accessor forgot to declare it as dependency in its local opam file.
cd dunireverse/ && git clone git@github.com:janestreet/accessor.git && cd ..
# also add accessor to `.deps`, so that its dependencies get installed
echo "accessor.v0.14.1" >> dunireverse/.deps

# with opam-monorepo, pull all dependencies into `duniverse/`
./dev/rev-deps.sh install-deps

# avoid building accessor
mv dunireverse/accessor/ duniverse/accessor/
sed -i '/^accessor.v0.14.1$/d' dunireverse/.deps

# remove duplicates that are both in `dunireverse/` and `duniverse/` due to multi-package structures
rm -rf duniverse/fix/ duniverse/ocaml-cstruct duniverse/bitstring duniverse/lwt

# make sure those dependencies get built during the `./dev/rev-deps.sh build` build despite not being declared as vendored
echo "cstruct" >> dunireverse/.deps
echo "lwt" >> dunireverse/.deps
echo "lwt_react" >> dunireverse/.deps

# work around a ctypes bug
rm -rf duniverse/ocaml-ctypes/ duniverse/ocaml-integers/ duniverse/bigarray-compat/
opam install ctypes-foreign -y

# fix visitors: it's not compatible with the 0.12.0 AST bump
cd dunireverse/visitors/ &&
git apply ../../dev/patch_visitors_src_Visitors_ml.diff \
../../dev/patch_visitors_src_VisitorsAnalysis_ml.diff \
../../dev/patch_visitors_src_VisitorsGeneration_ml.diff &&
cd ../..
