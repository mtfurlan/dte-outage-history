#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# */5 * * * * /$whatever/cronic /$whatever/scrape.sh

image=https://outage.dteenergy.com/outageLayerImage.png

date --iso=seconds >> dte-checks.log

lastImageDate=$(find output -type f -iname "*.png" | sort | tail -n1 | sed 's/output\/outage-\(.*\).png/\1/')
lastModifiedDate=$(TZ=GMT date -d "$lastImageDate" '+%a, %d %b %Y %T %Z')

echo "last png file: $lastImageDate, parsed to $lastModifiedDate"
echo "fetching png"
curl  \
    -s -S \
    --retry 5 \
    --dump-header /dev/fd/1 \
    --header "If-Modified-Since: $lastModifiedDate" \
    -o "output/outage-$(date --iso=seconds).png" \
    "$image"

image='https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/export?dpi=96&transparent=true&format=svg&bbox=-9696759.515792493%2C5077501.619710184%2C-8868793.625407506%2C5533066.308289812&bboxSR=102100&imageSR=102100&size=1354%2C745&f=image'

echo "fetching svg"
curl  \
    -s -S \
    --retry 5 \
    --dump-header /dev/fd/1 \
    -o "output/outage-$(date --iso=seconds).svg" \
    "$image"

geojson='https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/2/query?WHERE=OBJECTID%3E0&outFields=*&f=geojson'

# geojson is paginated if .exceededTransferLimit is true
date=$(date --iso=seconds)
finalFile="output/outage-$date.geojson"
exceededTransferLimit=true
offset=0
while [[ -n "$exceededTransferLimit" && "$exceededTransferLimit" == "true" ]]; do
    f="$finalFile-$offset"
    echo "fetching geojson, offset $offset into $f"
    curl  \
        -s -S \
        --retry 5 \
        --dump-header /dev/fd/1 \
        -o "$f" \
        "$geojson&resultOffset=$offset"

    exceededTransferLimit=$(jq -r '.exceededTransferLimit' "$f")
    offset=$(( offset + $(jq '.features | length' "$f") ))
    echo "exceededTransferLimit $exceededTransferLimit"
done

# merge all geojson to one file
#shellcheck disable=SC2086
jq -s '{"type": .[0].type, "crs": .[0].crs, "features": map(.features[])}' "$finalFile"-* > $finalFile
rm "$finalFile"-*
filename=$(basename "$finalFile")
cd output
tar -czvf "./$filename.tgz" "./$filename"
rm "$filename"
