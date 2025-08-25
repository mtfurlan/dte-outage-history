#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

set -x
# */5 * * * * /$whatever/cronic /$whatever/scrape.sh

attemptsMax=2

msg() {
    echo >&2 -e "${1-}"
}

die() {
    local msg=$1
    local code=${2-1} # default exit status 1
    msg "$msg"
    exit "$code"
}

mapServer=https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer
image=https://outage.dteenergy.com/outageLayerImage.png

date --iso=seconds >> dte-checks.log

# lastImageDate=$(find output -type f -iname "*.png" | sort | tail -n1 | sed 's/output\/outage-\(.*\).png/\1/')

retries=0
retryLoop () {
    retries=0
    until [ "$retries" -ge "$attemptsMax" ]; do
        lastfail=true
        $@ 1>&2 && lastfail=false && break
        retries=$((retries+1))
        sleep 5
    done

    echo $retries

    if [ "$lastfail" = true ]; then
        return 1
    else
        return 0
    fi
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

# initial and full are from the layer information
# this range loads a blank image? not sure why
initialXMin=-9250703.18187188
initialYMin=5210440.516810059
initialXMax=-9242543.529102448
initialYMax=5213259.13222807

# this seems to be the actual extent of the data
fullXMin=-9391354.1009
fullYMin=5134197.2961
fullXMax=-9174147.5244
fullYMax=5476370.6319

# these were some random numbers I picked and they worked and I forgot to check them for a while
# keeping them for consistancy
oopsXMin=-9696759.515792493
oopsYMin=5077501.619710184
oopsXMax=-8868793.625407506
oopsYMax=5533066.308289812
svg="$mapServer/export?dpi=96&transparent=true&format=svg&bbox=$oopsXMin%2C$oopsYMin%2C$oopsXMax%2C$oopsYMax&bboxSR=102100&imageSR=102100&size=1354%2C745&f=image"

#--dump-header /dev/fd/1 \
echo "fetching svg"
attempts=$(retryLoop curl  \
    --insecure \
    -s -S --stderr - \
    --retry 5 \
    -o "output/outage-$(date --iso=seconds).svg" \
    "$svg") 2>&1
if [ "$attempts" -ne 0 ]; then
    echo "svg attempts: $attempts" | tee -a dte-checks.log
fi
if [ "$attempts" -ge "$attemptsMax" ]; then
    failure=true
fi
if [ "$failure" = true ]; then
    die "failure after svg; giving up early"
fi


## geojson is paginated if .exceededTransferLimit is true
geojson="$mapServer/2/query?text=%25&f=geojson&units=esriSRUnit_Meter&returnTrueCurves=true"
date=$(date --iso=seconds)
finalFile="output/outage-$date.geojson"
exceededTransferLimit=true
offset=0
while [[ -n "$exceededTransferLimit" && "$exceededTransferLimit" == "true" ]]; do
    f="$finalFile-$offset"
    echo "fetching geojson, offset $offset into $f"
    attempts=$(retryLoop curl  \
        --insecure \
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
