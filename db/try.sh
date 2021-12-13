#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

file=raw.geojson
base=${file%.geojson}

#timestamp="2021-11-08T18:40:01-05:00"
timestamp=1636414801
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
FROM $base
EOF
)

ogr2ogr -f "PostgreSQL" PG:"dbname=postgres user=postgres" -nln test_table -overwrite -dialect sqlite -sql "$SQL" -lco GEOMETRY_NAME=geometry "$file"
psql -U postgres -c "SELECT * FROM test_table LIMIT 1"
