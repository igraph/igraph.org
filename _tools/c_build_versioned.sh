#!/bin/bash
set -euo pipefail

CFOLDER=${1}
CVERSIONS=${2}

CFOLDER_ABS=$(realpath $CFOLDER)
IFS=' '; read -ra CVERSIONS <<< $CVERSIONS

cd $CFOLDER_ABS
mkdir -p build_versions
mkdir -p build/doc/html
mkdir -p build/doc/pdf

for i in "${!CVERSIONS[@]}"; do
  version=${CVERSIONS[$i]}

  if [ "${version}" != "master" -a "${version}" != "develop" ]; then
    if [ -d "build/doc/html/${version}" -a -d "build/doc/pdf/${version}" ]; then
      echo "Skipping already built version: $version"
      continue
    fi
  fi

  echo "Building version: $version"

  git checkout $version
  if [ "${version}" = "master" -o "${version}" = "develop" ]; then
    # 'master' and 'develop' are "moving targets", we need to pull
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
