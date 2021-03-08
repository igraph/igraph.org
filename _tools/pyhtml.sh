#!/bin/bash

## Convert HTML files created by PyDoctor, to files to be used as 
## Jekyll inputs

if [ "$#" -ne 1 ] || ! [ -d "$1" ]; then
  echo "Usage: $0 DIR" >&2
  exit 1
fi

dir=$1

inhtml=`ls $dir/*.html`

header='---
layout: pydoctor
title: python-igraph API reference
mainheader: python-igraph API reference
lead: List of all classes, functions and methods in python-igraph
---
'

tmpfile=`mktemp /tmp/XXXXXX`

find $dir -name '*.html' -print0 | while IFS= read -r -d '' ih; do
    hf=`basename "${ih}"`

    printf "%b" "Converting ${hf}..."
    
    # YAML header
    echo "${header}" > ${tmpfile}
    
    # Begin raw
    echo '{% raw %}' >> ${tmpfile}

    # Main text
    cat "${ih}" |

    # Strip header and footer
    sed -n '1h;1!H;${;g;s/.*<body\([^>]*\)>/<div\1>/g;p;}' |
    sed -n '1h;1!H;${;g;s/<\/body>.*/<\/div>/;p;}' |

    # Remove navbar class, replace with pydoctor-navbar
    sed 's/class="navbar navbar-default"/class="pydoctor-navbar navbar-default"/g' |

    # Done 
    cat >> ${tmpfile}
    
    # End raw
    echo '{% endraw %}' >> ${tmpfile}
    
    # Replace
    cp ${tmpfile} "${ih}"
    
    printf " done.\n"
    
done;

rm -f ${tmpfile}

