#!/bin/bash
set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# db config
. "$DIR/.env"

to_import=$DIR/../scrape/output
to_import=$DIR/../import

# not deleting for debug, not great TODO cleanup
tmp=$(mktemp -d -t dte-import-XXXXXX)
echo "tmp dir is $tmp"


childPID=
trap 'set -x; echo "got SIGINT, exiting soon…"; [ -n "$childPID" ] && wait "$childPID"' SIGINT
file=

while IFS= read -r -d '' file <&3; do
    f=$(basename "$file")

    if [[ "$f" == *".geojson.tgz" ]]; then
        date=${f/#outage-/}
        date=${date/%.geojson.tgz/}
        timestamp=$(date -d "$date" +%s)
        echo "checking if '$f' already imported"
        if "$DIR"/runQuery -j --set "ts=$date" "SELECT EXISTS(SELECT 1 FROM outages WHERE timestamp=:'ts');" \
            | jq -e '.[0].exists' ; then
            echo "already imported $f"
            # TODO: continue in this ca,se but need to run the cleanup stuff once on everything
        else
            echo "importing $f"

            # the jq ensures that all these fields are at least populated with `null`
            # some number of the data between 2025-08-25 and 2026-06-09 doesn't ahve
            # any fields because something changed
            # only JOB_ID is guaranteed
            tar --to-stdout --force-local -axf "$file" \
                | tee "$tmp/debug.geojson" \
                | jq '.features = (.features | map(pick(.geometry, .type,
                    .properties.OBJECTID,
                    .properties.JOB_ID,
                    .properties.ADD_DTTM,
                    .properties.TYCOD,
                    .properties.NUM_CUST,
                    .properties.NUM_CUST_RESTORED,
                    .properties.TOAL_CUST_AFFECTED,
                    .properties.OFF_DTTM,
                    .properties.EST_REP_DTTM,
                    .properties.CAUSE,
                    .properties.DEV_NAME,
                    .properties.DEV_ID,
                    .properties.DEV_TYPE,
                    .properties.DEV_TYPE_NAME,
                    .properties.EVENT_STATUS,
                    .properties.DISPATCH_DTTM,
                    .properties.CREW_STATUS,
                    .properties.EST_REP_ENDDTTM,
                    .properties.CIRCUIT_EST_DTTM,
                    .properties.CIRCUIT_EST_ENDDTTM,
                    .properties.STORM_MODE,
                    .properties.SERVICE_CENTER,
                    .properties.SHAPE_Length,
                    .properties.SHAPE_Area)))' > "$tmp/file.geojson"

            if [[ "$(jq -r '.features | length' "$tmp/file.geojson")" -eq 0 ]]; then
                continue
            fi

            # this is somehow used by ogr2ogr to do a sqlite query on the geojson and
            # convert it into values that are good for our postgres table
            SQL=$(cat <<EOF
            SELECT
                datetime('$timestamp', 'unixepoch') AS timestamp,
                OBJECTID,
                JOB_ID,
                datetime(ADD_DTTM / 1000, 'unixepoch') AS ADD_DTTM,
                TYCOD,
                NUM_CUST,
                NUM_CUST_RESTORED,
                TOAL_CUST_AFFECTED,
                datetime(OFF_DTTM / 1000, 'unixepoch') AS OFF_DTTM,
                datetime(EST_REP_DTTM / 1000, 'unixepoch') AS EST_REP_DTTM,
                CAUSE,
                DEV_NAME,
                DEV_ID,
                DEV_TYPE,
                DEV_TYPE_NAME,
                EVENT_STATUS,
                datetime(DISPATCH_DTTM / 1000, 'unixepoch') AS DISPATCH_DTTM,
                CREW_STATUS,
                datetime(EST_REP_ENDDTTM / 1000, 'unixepoch') AS EST_REP_ENDDTTM,
                datetime(CIRCUIT_EST_DTTM / 1000, 'unixepoch') AS CIRCUIT_EST_DTTM,
                datetime(CIRCUIT_EST_ENDDTTM / 1000, 'unixepoch') AS CIRCUIT_EST_ENDDTTM,
                STORM_MODE,
                SHAPE_Length,
                SHAPE_Area,
                SERVICE_CENTER,
                Geometry
            FROM file -- NOTE: this must match the filename we're importing from
EOF
            )


            #-lco GEOMETRY_NAME=geometry
            # this actually runs the import of a file to the database
            ogr2ogr -of "PostgreSQL" PG:"dbname=dte user=postgres" -nln "outages" -append  -dialect sqlite -sql "$SQL"  "$tmp/file.geojson" &
            childPID=$!
            wait "$childPID"
        fi
    fi

    "$DIR"/runQuery --set "ts=$date" --set "f=$f" \
        "INSERT INTO imported (filename, imported) VALUES (filename=:'f' imported=:'ts');"

    "$DIR"/moveFile2SortedDir "$file"

done 3< <(find "$to_import" -type f -name "outage-*" -print0)

psql -c "SELECT COUNT(*) FROM outages"
