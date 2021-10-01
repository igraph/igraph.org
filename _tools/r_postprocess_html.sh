#!/bin/bash

## Convert HTML files created by R CMD INSTALL, to 
## file that can be used as Jekyll inputs

if [ "$#" -ne 2 ] || ! [ -d "$1" ] || ! [ -d "$2" ]; then
  echo "Usage: $0 SOURCE-DIR TARGET-DIR" >&2
  exit 1
fi

indir=$1
outdir=$2

header='---
layout: r-manual
title: igraph R manual pages
mainheader: R igraph manual pages
lead: Use this if you are using igraph from R
vmenu: true
'

basepkg="base boot class cluster codetools compiler datasets               \
    foreign graphics grDevices grid KernSmooth lattice MASS Matrix methods \
    mgcv nlme nnet parallel rpart spatial splines stats stats4 survival    \
    tcltk tools utils"

sedfile=`mktemp /tmp/XXXXXX`
echo -n > $sedfile
for i in $basepkg; do 
    printf "s/href=\\\"\\.\\.\\/\\.\\.\\/${i}\\/html\/\\([^\\\"]*\)\\.html/\\\"" >> $sedfile
    printf "href=\\\"http:\\/\\/www.inside-r.org\\/r-doc\\/${i}\\/\\\1/g\n" >> $sedfile
done

# echo foo | sed -f $sedfile 
outbase=`basename ${outdir}`

versions=$(ls $indir)
for version in $versions; do
  echo "Postprocessing docs for R version ${version}"

  inhtml=`ls ${indir}/${version}/*.html`
  mkdir -p ${outdir}/${version}
  
  for ih in ${inhtml}; do
      ihf=`basename ${ih}`
      oh=${outdir}/${version}/`basename ${ih}`
      
      # YAML header
      echo "${header}" > ${oh}
      echo "doctype: ${outbase}/" >> ${oh}
      echo "langversion: ${version}" >> ${oh}
      echo "---" >> ${oh}
      echo "" >> ${oh}
      echo "" >> ${oh}
      
      # Begin raw
      echo '{% raw %}' >> ${oh}
      
      # Main text
      cat ${ih} |
   
      # Strip header and footer    
      sed -n '1,/<body[ >]/!{ /<\/body>/,/<body[ >]/!p; }' |
  
      # Remove top table
      grep -v '^<table.*summary="page for ' | 
  
      # From index remove the top
      if [ ${ihf} = "00Index.html" ]; then 
  	sed -n '/<h2>Help Pages<\/h2>/,$p' | tail +2 
      else
  	cat
      fi |
  
      # Rewrite links to other packages, looks like 
      # we are only referring to base and recommended
      # packages, maybe only these are allowed by R CMD check
      sed -f $sedfile |
      
      # Done 
      cat >> ${oh}
      
      # End raw
      echo '{% endraw %}' >> ${oh}
  done;

  mv "${outdir}/${version}/00Index.html" "${outdir}/${version}/index.html"
done;

rm -f ${sedfile}
