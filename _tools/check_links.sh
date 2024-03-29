#!/bin/bash
#
# Checks for broken links on the generated site
#
# Make sure to run "make devserver" in another terminal before starting this
# script

# genindex.html and py-modindex.html are ignored because Sphinx generates them
# into the HTML file but we hide these with CSS

SCRIPT_ROOT=`dirname $0`
cd "${SCRIPT_ROOT}/.."

linkchecker \
    --check-extern \
    --ignore-url=https://www.googletagmanager.com \
    --ignore-url=genindex.html \
    --ignore-url=py-modindex.html \
	-o html \
    http://localhost:4000 \
	>_tools/linkchecker.html

echo "Link checker report ready in _tools/linkchecker.html"

