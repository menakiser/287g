#!/bin/bash

for year in {2021..2025}; do
  outdir="/Users/jimenakiser/Desktop/287g/data/wayback/idarrests/$year"
  mkdir -p "$outdir"
  
  waybackpack "https://www.ice.gov/identify-and-arrest/287g" \
    -d "$outdir" \
    --from-date "${year}0101" \
    --to-date "${year}1231"  --no-clobber  --delay 15 --delay-retry 30 --max-retries 1 --follow-redirects
done




