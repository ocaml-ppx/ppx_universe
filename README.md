# Ppx universe

This is a snapshot from March 3rd 2022 of all ppxlib reverse dependencies that meet the following standards:
- the package is on opem
- the package and all its dependencies either build with dune or have a port on opam-overlays
- the package builds with the 4.14 compiler
- the package has a version that builds with the last ppxlib version (0.24.0)

It has been created one by one [following these steps](dev/every_step.sh).

The reverse dependencies are in `rev-deps`. There's a list of all reverse dependencies that have been cloned into `rev-deps` [here](rev-deps/.deps).

## How to clone the ppx-universe
The reverse dependencies are embedded into the git structure as git submodules. To make sure you also clone the content of those submodules, it can be cloned as follows:
```
git clone --recurse-submodules https://github.com/ocaml-ppx/ppx_universe.git
```

When checking out another branch, you also need to update the submodules.

## How to build the packages in the ppx-universe
To build all ppxlib reverse dependencies in this project at once, run
```
./dev/helpers.sh build
```

Notice that on March 3rd 2022, the v0.15 release of the Jane Street packages wasn't merged into opam yet. So this universe checks out their last release tag before the v0.15 release. There's another branch called `4.14-bump-JS-only` contaning only the Jane Street reverse dependencies checked out to their v0.15 tag (with two of them missing due to v0.15 conflicts). On this branch, you can build the complement of the packages on that other branch by running
```
./dev/helpers.sh build non-js
```

There's a [list](rev-deps/.deps) containing all packages build with `build non-js` and another [list](rev-deps/.js-deps) containing all packages that are added to the build with `build`.

For any of those options, you need to be on a 4.14 switch with `dune`, `ctypes-foreign`, `stdlib-shims` and `stdcompat` installed. And you need to have `libsqlite3-dev` on your system.
