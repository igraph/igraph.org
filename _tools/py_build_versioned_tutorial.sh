#!/bin/bash
set -euo pipefail

PY=${1}
PYVERSIONS=${2}

PY_ABS=$(realpath $PY)
IFS=' '; read -ra PYVERSIONS <<< $PYVERSIONS

cd $PY_ABS
mkdir -p doc/tutorial

for i in "${!PYVERSIONS[@]}"; do
  version=${PYVERSIONS[$i]}

  if [ "${version}" != "master" -a "${version}" != "develop" ]; then
    if [ -d "doc/tutorial/${version}" ]; then
      echo "Skipping already built version: $version"
    fi
    continue
  fi

  echo "Building version: $version"

  git checkout $version
  if [ "${version}" = "master" -o "${version}" = "develop" ]; then
    # 'master' and 'develop' are "moving targets", we need to
    # pull
    git pull
  fi

  echo "Build docs"

  cd doc
  ../.venv/bin/python -m sphinx.cmd.build source tutorial/$version
  cd ..

  echo "Version ${version} done"

done
