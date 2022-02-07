#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# TODO: 2021-12-13 looks like between 2021-11-08 and now the GISRest stuff stopped supporting etag.
# Just always returns a new etag now.
# YAAAAY
# fdupes -dN output/

# */5 * * * * /$whatever/cronic /$whatever/scrape.sh

image=https://outage.dteenergy.com/outageLayerImage.png

date --iso=seconds >> dte-checks.log

lastImageDate=$(find output -type f -iname "*.png" | sort | tail -n1 | sed 's/output\/outage-\(.*\).png/\1/')
lastModifiedDate=$(TZ=GMT date -d "$lastImageDate" '+%a, %d %b %Y %T %Z')

echo "last png file: $lastImageDate, parsed to $lastModifiedDate"
curl  \
    -s -S \
    --dump-header /dev/fd/1 \
    --header "If-Modified-Since: $lastModifiedDate" \
    -o "output/outage-$(date --iso=seconds).png" \
    "$image"

image='https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/export?dpi=96&transparent=true&format=svg&bbox=-9696759.515792493%2C5077501.619710184%2C-8868793.625407506%2C5533066.308289812&bboxSR=102100&imageSR=102100&size=1354%2C745&f=image'

etagFile=.last-etag-svg

curl  \
    -s -S \
    --dump-header /dev/fd/1 \
    --etag-save $etagFile \
    --etag-compare $etagFile \
    -o "output/outage-$(date --iso=seconds).svg" \
    "$image"

geojson='https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/2/query?WHERE=OBJECTID%3E0&outFields=*&f=geojson'

etagFile=.last-etag-geojson

curl  \
    -s -S \
    --dump-header /dev/fd/1 \
    --etag-save $etagFile \
    --etag-compare $etagFile \
    -o "output/outage-$(date --iso=seconds).geojson" \
    "$geojson"
