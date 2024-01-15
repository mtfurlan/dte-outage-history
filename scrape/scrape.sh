#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# */5 * * * * /$whatever/cronic /$whatever/scrape.sh

attemptsMax=10

msg() {
    echo >&2 -e "${1-}"
}

die() {
    local msg=$1
    local code=${2-1} # default exit status 1
    msg "$msg"
    exit "$code"
}

image=https://outage.dteenergy.com/outageLayerImage.png

date --iso=seconds >> dte-checks.log

# lastImageDate=$(find output -type f -iname "*.png" | sort | tail -n1 | sed 's/output\/outage-\(.*\).png/\1/')

retries=0
retryLoop () {
    retries=0
    until [ "$retries" -ge "$attemptsMax" ]; do
        $@ 1>&2 && break
        retries=$((retries+1))
        sleep 5
    done
    echo $retries
}
failure=false
echo "fetching png"
attempts=$(retryLoop curl  \
    -s -S --stderr - \
    --retry 5 \
    -o "output/outage-$(date --iso=seconds).png" \
    "$image")
if [ "$attempts" -ne 0 ]; then
    echo "png attempts: $attempts" | tee -a dte-checks.log
fi
if [ "$attempts" -ge "$attemptsMax" ]; then
    failure=true
fi

image='https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/export?dpi=96&transparent=true&format=svg&bbox=-9696759.515792493%2C5077501.619710184%2C-8868793.625407506%2C5533066.308289812&bboxSR=102100&imageSR=102100&size=1354%2C745&f=image'

#--dump-header /dev/fd/1 \
echo "fetching svg"
set -x
attempts=$(retryLoop curl  \
    -s -S --stderr - \
    --retry 5 \
    -o "output/outage-$(date --iso=seconds).svg" \
    "$image") 2>&1
set +x
if [ "$attempts" -ne 0 ]; then
    echo "svg attempts: $attempts" | tee -a dte-checks.log
fi
if [ "$attempts" -ge "$attemptsMax" ]; then
    failure=true
fi

geojson='https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/2/query?WHERE=OBJECTID%3E0&outFields=*&f=geojson'

# geojson is paginated if .exceededTransferLimit is true
date=$(date --iso=seconds)
finalFile="output/outage-$date.geojson"
exceededTransferLimit=true
offset=0
while [[ -n "$exceededTransferLimit" && "$exceededTransferLimit" == "true" ]]; do
    f="$finalFile-$offset"
    echo "fetching geojson, offset $offset into $f"
    attempts=$(retryLoop curl  \
        -s -S --stderr - \
        --retry 10 \
        -o "$f" \
        "$geojson&resultOffset=$offset") 2>&1
    if [ "$attempts" -ne 0 ]; then
        echo "geojson attempts at offset $offset: $attempts" | tee -a dte-checks.log
    fi
    if [ "$attempts" -ge "$attemptsMax" ]; then
        failure=true
        die "failed to fetch geojson at $date, aborting"
    fi

    exceededTransferLimit=$(jq -r '.exceededTransferLimit' "$f")
    offset=$(( offset + $(jq '.features | length' "$f") ))
    #echo "exceededTransferLimit $exceededTransferLimit"
done

# merge all geojson to one file
#shellcheck disable=SC2086
jq -s '{"type": .[0].type, "crs": .[0].crs, "features": map(.features[])}' "$finalFile"-* > $finalFile
rm "$finalFile"-*
filename=$(basename "$finalFile")
cd output
tar -czvf "./$filename.tgz" "./$filename"
rm "$filename"

if [ "$failure" = true ]; then
    die "too many retries"
fi
