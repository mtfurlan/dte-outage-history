#!/bin/bash
set -euo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

runQuery()
{
    chomp() {
        #https://stackoverflow.com/a/3352015/2423187
        local var="$*"
        # remove leading whitespace characters
        var="${var#"${var%%[![:space:]]*}"}"
        # remove trailing whitespace characters
        var="${var%"${var##*[![:space:]]}"}"
        printf '%s' "$var"
    }

    sql=${1:-}
    if [ -z "$sql" ]; then
        help "need to pass sql command if non-interactive"
    fi

    #remove comments
    # shellcheck disable=SC2001
    sql=$(echo "$sql" | sed 's/ *--.*$//')
    # remove newline
    sql=${sql//[$'\n\r ']/ }

    #escape quote
    sql=${sql//\"/\\\\\\\"}

    #escape $
    sql=${sql//\$/\\\\$}

    sql=$(chomp "$sql")

    if [[ "${sql^^}" == "SELECT"* ]] || [[ "${sql^^}" == *"RETURNING"* ]]; then
        sql="WITH sq AS (${sql/;/}) SELECT json_agg(row_to_json(sq)) FROM sq;"
    fi

    psql -c "$sql" \
        | grep -v "^--*\W\?$\|json_agg\|^(1 row)" | jq -c .
}
PGPORT=5432
PGPASSWORD=postgres
PGUSER=postgres
PGDATABASE=dte
PGHOST=localhost
export PGPORT PGPASSWORD PGUSER PGDATABASE PGHOST

psql -c "DROP TABLE IF EXISTS outages"

psql 1>&2 << EOF
CREATE TABLE IF NOT EXISTS outages (
    --ogc_fid SERIAL PRIMARY KEY,
    timestamp TIMESTAMP WITH TIME ZONE,
    job_id TEXT,
    objectid INT,
    add_dttm TIMESTAMP WITH TIME ZONE,
    tycod TEXT,
    num_cust INT,
    num_cust_restored INT,
    toal_cust_affected INT,
    off_dttm TIMESTAMP WITH TIME ZONE,
    est_rep_dttm TIMESTAMP WITH TIME ZONE,
    cause TEXT,
    dev_name TEXT,
    dev_id INT,
    dev_type INT,
    dev_type_name TEXT,
    event_status TEXT,
    dispatch_dttm TIMESTAMP WITH TIME ZONE,
    crew_status TEXT,
    est_rep_enddttm TIMESTAMP WITH TIME ZONE,
    circuit_est_dttm TIMESTAMP WITH TIME ZONE,
    circuit_est_enddttm TIMESTAMP WITH TIME ZONE,
    storm_mode TEXT,
    shape_length DOUBLE PRECISION,
    shape_area DOUBLE PRECISION,
    service_center TEXT,
    geometry geography(Polygon,4326),
    PRIMARY KEY(timestamp, job_id)
);
EOF
# not deleting for debug, not great TODO cleanup
tmp=$(mktemp -d -t dte-import-XXXXXX)
echo "tmp dir is $tmp"
while IFS= read -r -d '' file <&3; do
    date=$(basename "$file")
    date=${date/#outage-/}
    date=${date/%.geojson.tgz/}
    timestamp=$(date -d "$date" +%s)

    if [[ "$(runQuery "SELECT COUNT(*) FROM outages WHERE timestamp='$date';" | jq -r .[0].count)" -eq 0 ]]; then
        echo "already imported $file"
        continue
    else
        echo "importing $file"
    fi
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
    ogr2ogr -of "PostgreSQL" PG:"dbname=dte user=postgres" -nln "outages" -append  -dialect sqlite -sql "$SQL"  "$tmp/file.geojson"

done 3< <(find "$DIR/../scrape/output" -type f -name "outage-*.geojson.tgz" -print0)

psql -c "SELECT COUNT(*) FROM outages"
