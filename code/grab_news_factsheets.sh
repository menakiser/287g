#!/bin/bash

for year in {2011..2014}; do
  outdir="/Users/jimenakiser/Desktop/287g/data/raw/wayback/news_factsheets/$year"
  mkdir -p "$outdir"
  
  waybackpack "http://www.ice.gov/news/library/factsheets/287g.htm" \
    -d "$outdir" \
    --from-date "${year}0101" \
    --to-date "${year}1231"  --no-clobber  --delay 15 --delay-retry 30 --max-retries 1 --follow-redirects
done




