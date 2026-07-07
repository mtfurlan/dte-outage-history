#!/bin/bash
msg() {
    echo >&2 -e "${1-}"
}

die() {
    local msg=$1
    local code=${2-1} # default exit status 1
    msg "$msg"
    exit "$code"
}
cd "$(dirname "${BASH_SOURCE[0]}")/../" || die "failed to cd?"

date=$(date --iso)

ssh personalAWS tar zcvf - dte-outage-history/scrape/output/ | tar zxf -
missing=false
while read -r f ; do
    if ! [[ -f "$f" ]]; then
        echo "$f missing"
        missing=true
    fi
done < <(ssh personalAWS 'find dte-outage-history/scrape/output/ -type f | grep -v "'"$date"'"' )
if [ "$missing" = true ]; then
    die "missing files, not deleting anything"
else
    ssh personalAWS 'find dte-outage-history/scrape/output/ -type f | grep -v "'"$date"'" | xargs -r rm'
fi
find dte-outage-history/scrape/output/ -type f -print0 | xargs -r0 mv -n -t dte-outage-history/raw_files/import/

while IFS= read -r -d '' file <&3; do
    target="dte-outage-history/raw_files/import/$(basename "$file")"
    if diff -q "$file"  "$target"; then
        rm "$file"
    else
        echo "$file and $target differ"
    fi
done 3< <(find dte-outage-history/scrape/output/ -type f -print0)
