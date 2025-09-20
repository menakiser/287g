#!/bin/bash

for year in {2017..2021}; do
  outdir="/Users/jimenakiser/Desktop/287g/data/wayback/icegov/$year"
  mkdir -p "$outdir"
  
  waybackpack "http://www.ice.gov/287g/" \
    -d "$outdir" \
    --from-date "${year}0101" \
    --to-date "${year}1231"  --no-clobber  --delay 15 --delay-retry 30 --max-retries 1 --follow-redirects
done




