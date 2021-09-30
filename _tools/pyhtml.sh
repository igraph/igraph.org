#!/bin/bash

## Convert HTML files created by PyDoctor, to files to be used as 
## Jekyll inputs

if [ "$#" -ne 1 ] || ! [ -d "$1" ]; then
  echo "Usage: $0 DIR" >&2
  exit 1
fi

dir=$1

header_pydoctor='---
layout: pydoctor
title: python-igraph API reference
mainheader: python-igraph API reference
lead: List of all classes, functions and methods in python-igraph
vmenu: true
'

header_epydoc='---
layout: epydoc
title: python-igraph manual
mainheader: python-igraph manual
lead: For using igraph from Python
vmenu: true
'


for version in $dir; do
  [ version = "stamp" ] && continue

  # Check if the docs were done by epydoc or pydoctor
  if echo "0.8.1 0.9.0" | grep -w $version > /dev/null; then
    docgenerator=epydoc
    header=$header_epydoc
  else
    docgenerator=pydoctor
    header=$header_pydoctor
  fi

  inhtml=`ls $dir/$version/*.html`
  
  tmpfile=`mktemp /tmp/XXXXXX`
  
  find $dir -name '*.html' -print0 | while IFS= read -r -d '' ih; do
      hf=`basename "${ih}"`
  
      printf "%b" "Converting ${hf}..."
      
      # YAML header
      echo "${header}" > ${tmpfile}
      echo "langversion: $version" >> ${tmpfile}
      echo "---" >> ${tmpfile}
      
      # Begin raw
      echo '{% raw %}' >> ${tmpfile}
  
      if [ docgenerator = "pydoctor" ]; then
        # Main text
        cat "${ih}" |
  
        # Strip header and footer
        sed -n '1h;1!H;${;g;s/.*<body\([^>]*\)>/<div\1>/g;p;}' |
        sed -n '1h;1!H;${;g;s/<\/body>.*/<\/div>/;p;}' |
  
        # Remove navbar class, replace with pydoctor-navbar
        sed 's/class="navbar navbar-default"/class="pydoctor-navbar navbar-default"/g' |
  
        # Done 
        cat >> ${tmpfile}
      else
        # Main text
        cat ${ih} |
  
        # Strip header and footer
        sed -n '1h;1!H;${;g;s/.*<body\([^>]*\)>/<div\1/g;p;}' |
        sed -n '1h;1!H;${;g;s/<\/body>.*/<\/div>/;p;}' |
  
        # Take out links to frames / no frames
        sed -n '1h;1!H;${;g;s/\[[^[]*frames.html[^[]*]//;p;}' |
  
        # Repair a bug in epydoc
        sed 's/^<\/div>\(<a name=\)/\1/' |
  
        # Remove link from navbar
        sed 's/<a class="navbar" [^>]*_top[^>]*igraph\.org[^>]*>[^<]*<\/a>//' |
  
        # Remove navbar class, replace with epynavbar
        sed 's/class="navbar"/class="epynavbar"/g' |
  
        # Done 
        cat >> ${tmpfile}
      fi
  
      # End raw
      echo '{% endraw %}' >> ${tmpfile}
      
      # Replace
      cp ${tmpfile} "${ih}"
      
      printf " done.\n"
      
  done;
  
  rm -f ${tmpfile}

done
