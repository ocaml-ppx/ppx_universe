#!/bin/bash
set -e

opam update

# allow packages in the work space that don't directly build with dune, but have a dune port in the dune-universe
opam repo add dune-universe git+https://github.com/dune-universe/opam-overlays.git

# to allow reverse dependencies that depend on stdcompat: add a fork of opam-overlays containing a broken opam-overlay for stdcompat.
# that tricks opam-monorepo into into accepting packages that require stdcompat.
# later, remove stdcompat from the duniverse and install it with opam (it doesn't have any dependencies)
opam repo add dune-universe-pitag git+https://github.com/pitag-ha/opam-overlays.github

# for opam metadata queries, use Jane Street's opam-repository containing the previews for their v0.15 releases rather than the opam default repo (on which the last version of the Jane Street packages is still v0.14)
opam repo add jane-street-repo git@github.com:janestreet/main-opam-repository.git#janestreet-v0.15

# pin to an old opam-monorepo since the last version has a bug
opam pin add opam-monorepo https://github.com/ocamllabs/opam-monorepo.git#8054037deccc8b50e3e0755a0bbf4976f2360aab -y

# pin ppxlib to the current branch giving it version 0.24.0.
# if not, opam-monorepo will give it the place-holder version zdev and run into resolver conflicts for packages explicitly requiring ppxlib <= 0.24.0
opam pin ppxlib.0.24.0 .

# clone all Jane Street reverse dependencies into `rev-deps/` and add them to `rev-deps/.deps`
./dev/helpers.sh pull janestreet

# re-add ppx_sexp_message without checking it out to the last release tag: seems like the git history on that repo has been messed up and now the release tags point to commits that don't exist anymore
git submodule deinit -f -- rev-deps/ppx_sexp_message
rm -rf .git/modules/rev-deps/ppx_sexp_message
git rm -f rev-deps/ppx_sexp_message
cd rev-deps &&
git submodule add https://github.com/janestreet/ppx_sexp_message.git ppx_sexp_message &&
cd ..

# remove two of the rev-deps that aren't compatible with the Jane Street v0.15 world (instead they're included in their v0.14 version into the universe for non Jane Street packages)
sed -i '/ppx_fail/d' rev-deps/.deps # doesn't have a v0.15 release preview
sed -i '/hardcaml/d' rev-deps/.deps # in its v0.15 version, it has upgraded zarith from >=1.5 to >= 1.11. the later isn't on opam-overlays

# pull in the dependencies of the reverse dependencies
./dev/helpers.sh install-deps

# The current scope doesn't define package "stdcompat".
rm -rf duniverse/stdcompat

# as mentioned above, remove stdcompat from the duniverse and install it with opam instead
rm -rf duniverse/stdcompat
opam install stdcompat
