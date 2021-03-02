# Ppx universe

This is a snapshot from March 1st 2021 of all ppxlib reverse dependencies that meet the following standard:
- the package and all its dependencies either build with dune or have a port on dune-universe
- the package builds with the 4.10 compiler
- the package has a version/branch that builds with the last ppxlib version (0.22.0)

It has been created one by one with [this script](dev/create_workspace.sh).

You can clone it via
```
git clone --recurse-submodules <url>
```
and build all reverse dependencies at once via
```
./dev/rev-deps.sh build
```
