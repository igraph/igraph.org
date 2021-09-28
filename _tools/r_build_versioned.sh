#!/bin/bash
set -euo pipefail

RFOLDER=${1}
RVERSIONS=${2}
CRAN_VERSION=${3}

RFOLDER_ABS=$(realpath $RFOLDER)
IFS=' '; read -ra RVERSIONS <<< $RVERSIONS

cd $RFOLDER_ABS
mkdir -p build_versions
mkdir -p build/doc/html
mkdir -p build/doc/pdf

for i in "${!RVERSIONS[@]}"; do
  version=${RVERSIONS[$i]}

  echo "Building version: $version"

  mkdir -p build_versions/$version
  cd build_versions/$version

  echo "Download from CRAN"

  if [ ! -f igraph_${version}.tar.gz ]; then
   # The latest version is here, the rest in an "Archive" folder
    if [ ${version} == ${CRAN_VERSION} ]; then
      curl -o igraph_${version}.tar.gz -s https://cran.r-project.org/src/contrib/igraph_${version}.tar.gz
    else
      curl -o igraph_${version}.tar.gz -s https://cran.r-project.org/src/contrib/Archive/igraph/igraph_${version}.tar.gz
    fi
  fi
  tar --strip-components 1 -xzf igraph_${version}.tar.gz

  echo "Build docs"

  TMP=$(mktemp -d /tmp/.XXXXX)
  R CMD INSTALL --html --no-R --no-configure --no-inst \
    --no-libs --no-exec --no-test-load -l ${TMP} .

  R CMD Rd2pdf --no-preview --force -o igraph.pdf .

  cd ../..

  echo "Reorganize folders"
  cp -r ${TMP}/igraph/html build/doc/html/$version
  mkdir -p build/doc/pdf/$version/
  cp -r build_versions/$version/igraph.pdf build/doc/pdf/$version/

  echo "Version ${version}: done"

done
