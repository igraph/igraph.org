#!/bin/bash

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

  echo "Building version: $version"

  git checkout $version

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
  cp -r build_versions/$version/doc/html build/doc/html/$version
  mkdir -p build/doc/pdf/$version/
  cp -r build_versions/$version/doc/igraph-docs.pdf build/doc/pdf/$version/

  echo "Version ${version}: done"

done
