#!/bin/bash
set -euo pipefail

PY=${1}
PYVERSIONS=${2}
PYCVERSIONS=${3}

PY_ABS=$(realpath $PY)
IFS=' '; read -ra PYVERSIONS <<< $PYVERSIONS
IFS=' '; read -ra PYCVERSIONS <<< $PYCVERSIONS

cd $PY_ABS
mkdir -p doc/api_versions

for i in "${!PYVERSIONS[@]}"; do
  version=${PYVERSIONS[$i]}
  c_version=${PYCVERSIONS[$i]}

  echo "Building version: $version (C version: $c_version)"

  git checkout $version

  echo "Build C core matching this version"

  rm -rf vendor/build/igraph vendor/install/igraph
  # Check cache
  if [ -d vendor/cache/igraph_${c_version} ]; then
    echo "Copy C core cache for version: ${c_version}"
    cp -r vendor/cache/igraph_${c_version} vendor/install/igraph
  # or build from scratch
  else
    cd vendor/source/igraph
    git checkout $c_version
    cd ../../..
  fi

  echo "Build extension"

  .venv/bin/python setup.py build

  # Cache C core
  if [ ! -d vendor/cache/igraph_${c_version} ]; then
    mkdir -p vendor/cache
    cp -r vendor/install/igraph vendor/cache/igraph_${c_version}
  fi

  .venv/bin/python setup.py install

  echo "Build docs"

  # Old docs use epydoc, which is python2 only. So fix that
  if [ -f scripts/epydoc-patched ]; then
    sed -i 's/python -m epydoc/python2 -m epydoc/' scripts/mkdoc.sh
    sed -i 's|/usr/bin/env python|/usr/bin/env python2|' scripts/epydoc-patched
  fi

  scripts/mkdoc.sh

  # Restore initial file, to ensure a clean tree for future git checkout
  if [ -f scripts/epydoc-patched ]; then
    git checkout HEAD scripts/mkdoc.sh
    git checkout HEAD scripts/epydoc-patched
  fi

  echo "Copy docs"

  rm -rf doc/api_versions/${version}
  cp -r doc/api/html doc/api_versions/${version}
  rm -rf doc/api/*

  echo "Version ${version} (C core: ${c_version}): done"

done
