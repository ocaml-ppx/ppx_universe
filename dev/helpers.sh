#!/bin/bash
set -euo pipefail

pull () {
  case $1 in
    janestreet|js)
      JS_GREP_ARG=""
      ;;
    *)
      JS_GREP_ARG="-v"
      ;;
  esac

  # Get a first list of revdeps candidate
  REVDEPS=$(opam list -s --depends-on ppxlib.0.24.0 --coinstallable-with ocaml.4.14.0)

  TRUE_REVDEPS=""
  for d in $REVDEPS
  do
    ALL_VERS=$(opam show --field=all-versions $d)
    LATEST_VER=${ALL_VERS##* }
    deps=$(opam show --field=depends: $d.$LATEST_VER)
    # Filter out packages that come from Janestreet mono repo and
    # packages whose latest version isn't a rev dep anymore
    if (opam show --field=maintainer: $d.$LATEST_VER | grep $JS_GREP_ARG "janestreet\|Jane Street" > /dev/null) &&
      (echo "$deps" | grep "ppxlib" > /dev/null) &&
      (echo "$deps" | grep "dune" > /dev/null)
    then
      TRUE_REVDEPS="$TRUE_REVDEPS $d.$LATEST_VER"
    fi
  done

  if [ -z "$TRUE_REVDEPS" ]
  then
    echo "No revdeps found for ppxlib"
    exit 1
  fi

  mkdir -p rev-deps
  cd rev-deps

  for d in $TRUE_REVDEPS
  do
    echo "$d" >> .deps
  done

  cat .deps

  for d in $TRUE_REVDEPS
  do
    basename=${d%%.*}
    ver=${d#*.}
    tmp=$(opam show --field=dev-repo: $d)
    tmp=${tmp%\"}
    tmp=${tmp#\"}
    DEV_REPO=${tmp#git+}
    git submodule add $DEV_REPO $basename || echo "couldn't add $basename: $DEV_REPO" >> ../dev/.do_manually.txt
    case $1 in
      janestreet|js)
        # To checkout to the latest released version
        (cd $basename &&
        (git checkout $ver || git checkout v$ver || echo "couldn't checkout $basename to $ver or v$ver" >> ../dev/.do_manually.txt) &&
        cd ..) || echo "couldn't cd into $basename"
        ;;
      *)
        :
        ;;
    esac
  done
  cd ..
}

install_deps () {
  PACKAGES="ppxlib.0.24.0"
  while read line
  do
    PACKAGES="$PACKAGES $line"
  done < rev-deps/.deps
  opam  monorepo lock --lockfile rev-deps.locked -v -v --build-only $PACKAGES --ocaml-version 4.14.0|| echo "opam monorepo lock has failed" &&
  opam monorepo pull --lockfile rev-deps.locked || echo "opam monorepo pull has failed"
}

build () {
  PACKAGES="ppxlib.install"
  while read line
  do
    if [ ! -z "$line" ]
    then
      basename=${line%%.*}
      dir=$(find rev-deps/ -name "$basename.opam" -exec dirname {} \;)
      PACKAGES="$PACKAGES $dir/$basename.install"
    fi
  done < rev-deps/.deps
  echo $PACKAGES
  dune build --profile release $PACKAGES
}

list_required_by () {
  ALL_REV_DEPS=$(opam list -s --depends-on=$1 --recursive)
  while read line
  do
    if [ ! -z "$line" ]
    then
      basename=${line%%.*}
      echo $ALL_REV_DEPS | grep -o $basename || true
    fi
  done < rev-deps/.deps
}

# Way slower than list_required_by but more accurate
list_required_by_with_version () {
  while read line
  do
    if (opam list --required-by=$line --recursive | grep $1 > /dev/null)
    then echo $line
    fi
  done < rev-deps/.deps
}

find_culprit (){
while read line
do
  if opam monorepo lock --build-only $line --ocaml-version 4.14.0
  then
    rm ${line%%.*}.opam.locked
    echo "---------------------------"
  else
    echo "'opam monorepo lock --build-only $line --ocaml-version 4.14.0' failed"
    return 0
  fi
done < rev-deps/.deps
}

# bisect_monorepo_lock (){
# PACKAGES="ppxlib"
# max=$(wc -l < rev-deps/.deps)
# line_num=0
# while read line && ((line_num < max))
# do
# PACKAGES="$PACKAGES $line"
# line_num=((line_num + 1))
# done < rev-deps/.deps
# opam monorepo lock --build-only -v -v $PACKAGES --ocaml-version 4.14.0
# }

clean_up_submodules () {
  while read line
  do
    basename=${line%%.*}
    git submodule deinit -f -- rev-deps/$basename || true
    git rm -f rev-deps/$basename || true
  done < rev-deps/.deps
  rm -rf .git/modules
  rm .gitmodules
  touch .gitmodules
}

if [ $# -ne 2 ]
then
  SND_ARG=""
else
  SND_ARG="$2"
fi

case $1 in
  "")
    pull
    install_deps
    build
    ;;
  pull)
    pull "$SND_ARG"
    ;;
  install-deps)
    install_deps "$SND_ARG"
    ;;
  build)
    build
    ;;
  list-required-by)
    list_required_by "$SND_ARG"
    ;;
  list-required-by-with-version)
    list_required_by_with_version "$SND_ARG"
    ;;
  clean-up-submodules)
    clean_up_submodules
    ;;
  find-culprit)
    find_culprit
    ;;
  *)
    echo "invalid subcommand $1"
    exit 1
esac
