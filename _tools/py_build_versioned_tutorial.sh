#!/bin/bash
set -euo pipefail

PY=${1}
PYVERSIONS=${2}

PY_ABS=$(realpath $PY)
IFS=' '; read -ra PYVERSIONS <<< $PYVERSIONS

cd $PY_ABS
mkdir -p doc/tutorial_versions

for i in "${!PYVERSIONS[@]}"; do
  version=${PYVERSIONS[$i]}

  echo "Building version: $version"

  git checkout $version

  echo "Build docs"

  cd doc
  ../.venv/bin/python -m sphinx.cmd.build source tutorial_versions/$version
  cd ..

  echo "Version ${version} done"

done
