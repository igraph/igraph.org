#!/bin/bash

## Convert HTML files created by R CMD INSTALL, to 
## file that can be used as Jekyll inputs

if [ "$#" -ne 3 ] || ! [ -d "$1" ] || ! [ -d "$2" ]; then
  echo "Usage: $0 SOURCE-DIR TARGET-DIR LATEST-VERSION" >&2
  exit 1
fi

indir=${1}
outdir=${2}
latest=${3}

header='---
layout: r-manual
title: igraph R manual pages
mainheader: R igraph manual pages
lead: Use this if you are using igraph from R
vmenu: true
'

basepkgs="base compiler datasets graphics grDevices grid methods parallel \
        splines stats stats4 tcltk tools utils"
cranpkgs="boot class cluster codetools foreign KernSmooth lattice MASS \
        Matrix mgcv nlme nnet rpart spatial survival"

sedfile=`mktemp /tmp/XXXXXX`
echo -n > $sedfile
printf "s/href=\\\"\\.\\.\\/\\.\\.\\/igraph\\/help\\/\\([^\\\"]*\)\\.html/" >> $sedfile
printf "href=\\\"\\\1.html/g\n" >> $sedfile
printf "s/href=\\\"00Index\\.html/" >> $sedfile
printf "href=\\\"index.html/g\n" >> $sedfile
for i in $basepkgs; do 
    printf "s/href=\\\"\\.\\.\\/\\.\\.\\/${i}\\/html\\/\\([^\\\"]*\)\\.html/" >> $sedfile
    printf "href=\\\"https:\\/\\/rdrr.io\\/r\\/${i}\\/\\\1.html/g\n" >> $sedfile
    printf "s/href=\\\"\\.\\.\\/\\.\\.\\/${i}\\/help\\/\\([^\\\"]*\)\\.html/" >> $sedfile
    printf "href=\\\"https:\\/\\/rdrr.io\\/r\\/${i}\\/\\\1.html/g\n" >> $sedfile
done
for i in $cranpkgs; do 
    printf "s/href=\\\"\\.\\.\\/\\.\\.\\/${i}\\/html\\/\\([^\\\"]*\)\\.html/" >> $sedfile
    printf "href=\\\"https:\\/\\/rdrr.io\\/cran\\/${i}\\/man\\/\\\1.html/g\n" >> $sedfile
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
      oh=${outdir}/${version}/${ihf}
      
      # YAML header
      echo "${header}" > ${oh}
      echo "doctype: ${outbase}/" >> ${oh}
      echo "langversion: ${version}" >> ${oh}
      if [ ${version} = ${latest} ]; then
        if [ ${ihf} = "00Index.html" ]; then
          latest_path=${outdir}/latest/index.html
        else
          latest_path=${outdir}/latest/${ihf}
        fi
        echo "redirect_from:" >> ${oh}
        echo "  - ${latest_path}" >> ${oh}
      fi
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
  
      # Rewrite links to other packages
      sed -f $sedfile |
      
      # Done 
      cat >> ${oh}
      
      # End raw
      echo '{% endraw %}' >> ${oh}
  done;

  mv "${outdir}/${version}/00Index.html" "${outdir}/${version}/index.html"
done;
mv "${outdir}/latest/00Index.html" "${outdir}/latest/index.html"

rm -f ${sedfile}
