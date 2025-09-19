#!/bin/bash
set -euo pipefail

CFOLDER=${1}
CVERSIONS=${2}

CFOLDER_ABS=$(realpath $CFOLDER)
IFS=' '
read -ra CVERSIONS <<<$CVERSIONS

ROOT_ABS=$(pwd)

cd $CFOLDER_ABS
mkdir -p build_versions
mkdir -p build/doc/html
mkdir -p build/doc/pdf

for i in "${!CVERSIONS[@]}"; do
  version=${CVERSIONS[$i]}

  if [ "${version}" != "main" -a "${version}" != "develop" ]; then
    SKIP=0
    if [ -f "${ROOT_ABS}/c/html/${version}/index.html" -a -d "${ROOT_ABS}/c/pdf/${version}" ]; then
      SKIP=1
    fi
    if [ -d "build/doc/html/${version}" -a -d "build/doc/pdf/${version}" ]; then
      SKIP=1
    fi
    if [ "x$SKIP" = x1 ]; then
      echo "Skipping already built version: $version"
      continue
    fi
  fi

  echo "Building version: $version"

  git checkout $version
  if [ "${version}" = "main" -o "${version}" = "develop" ]; then
    # 'main' and 'develop' are "moving targets", we need to pull
    git pull
  fi

  echo "Build docs"

  if [ ! -d build_versions/$version ]; then
    mkdir build_versions/$version
    cd build_versions/$version
    cmake ../..
  else
    cd build_versions/$version
  fi
  make html
  make pdf
  cd ../..

  echo "Reorganize folders"
  rm -rf build/doc/html/$version
  cp -r build_versions/$version/doc/html build/doc/html/$version
  mkdir -p build/doc/pdf/$version/
  cp -r build_versions/$version/doc/igraph-docs.pdf build/doc/pdf/$version/

  echo "Version ${version}: done"

done
