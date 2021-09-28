#!/bin/bash
# Patches PyDoctor to make it suitable to build python-igraph's documentation
# until our patches get upstreamed

if [ "x$1" = x ]; then
    echo "Usage: $0 python-build-dir"
    exit 1
fi

set -e

ROOT="`pwd`"

cd "$1"
.venv/bin/pip uninstall -y pydoctor
.venv/bin/pip install pydoctor==21.2.2
PYDOCTOR_DIR=`.venv/bin/python -c 'import os,pydoctor;print(os.path.dirname(pydoctor.__file__))'`

cd "${PYDOCTOR_DIR}"
# patch is confirmed to work with pydoctor 21.2.2
patch -r deleteme.rej -N -p2 <${ROOT}/_tools/pydoctor-21.2.2.patch 2>/dev/null
rm -f deleteme.rej


