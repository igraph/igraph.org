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
mkdir -p doc/tutorial

for i in "${!PYVERSIONS[@]}"; do
  version=${PYVERSIONS[$i]}
  c_version=${PYCVERSIONS[$i]}

  if [ "${version}" != "master" -a "${version}" != "develop" ]; then
    if [ -d "doc/api_versions/${version}" ]; then
      echo "Skipping already built version: $version (C version: $c_version)"
      continue
    fi
  fi

  echo "Building version: $version (C version: $c_version)"

  git checkout $version
  if [ "${version}" = "master" -o "${version}" = "develop" ]; then
    # 'master' and 'develop' are "moving targets", we need to pull
    git pull
  fi
  git submodule update --init --recursive

  echo "Build C core matching this version"

  rm -rf vendor/build/igraph vendor/install/igraph
  # Check cache
  if [ "${c_version}" != "master" -a "${c_version}" != "develop" -a -d vendor/cache/igraph_${c_version} ]; then
    echo "Copy C core cache for version: ${c_version}"
    cp -r vendor/cache/igraph_${c_version} vendor/install/igraph
  fi

  echo "Build extension"

  .venv/bin/python setup.py build

  # Cache C core
  if [ "${c_version}" != "master" -a "${c_version}" != "develop" -a ! -d vendor/cache/igraph_${c_version} ]; then
    mkdir -p vendor/cache
    cp -r vendor/install/igraph vendor/cache/igraph_${c_version}
  fi

  # Clean up previous builds and then do a fresh build
  rm -rf build
  rm -rf .venv/lib/python3.*/site-packages/igraph
  rm -rf .venv/lib/python3.*/site-packages/python_igraph*.egg
  .venv/bin/python setup.py install
  .venv/bin/pip install -U pydoctor

  echo "Build API docs"

  # Old docs use epydoc, which is python2 only. So fix that
  if [ -f scripts/epydoc-patched ]; then
    sed -i 's/python -m epydoc/python2 -m epydoc/' scripts/mkdoc.sh
    sed -i 's|/usr/bin/env python|/usr/bin/env python2|' scripts/epydoc-patched
  fi

  # Clear old docs
  rm -rf doc/api doc/html

  # Build docs
  scripts/mkdoc.sh

  # Restore initial file, to ensure a clean tree for future git checkout
  if [ -f scripts/epydoc-patched ]; then
    git checkout HEAD scripts/mkdoc.sh
    git checkout HEAD scripts/epydoc-patched
  fi

  echo "Copy API docs and manual to their final places"

  # scripts/mkdoc.sh builds the API docs _and_ the tutorial for python-igraph
  # 0.10 and later but not for 0.9.9 and earlier so we need to build the
  # tutorial separately if needed. Also, the API docs will be in doc/html/api
  # with 0.10 but in doc/api for 0.9.9 and earlier
  rm -rf doc/api_versions/${version} doc/tutorial/${version}
  if [ -d doc/html ]; then
    # python-igraph 0.10 and later
    mkdir -p doc/api_versions/${version}
    mkdir -p doc/tutorial/${version}
    cp -r doc/html/api/* doc/api_versions/${version}
    rm -rf doc/html/api
    cp -r doc/html/* doc/tutorial/${version}
  else
    # python-igraph 0.9.9 and earlier
    cd doc
    ../.venv/bin/python -m sphinx.cmd.build source tutorial/${version}
    cd ..
    mkdir -p doc/api_versions/${version}
    cp -r doc/api/html/* doc/api_versions/${version}
  fi

  echo "Version ${version} (C core: ${c_version}): done"

done
