#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

table=outage_events

psql -U postgres -c "drop table if exists $table"
psql -U postgres -c "
CREATE TABLE IF NOT EXISTS $table (
    outageEventPK SERIAL PRIMARY KEY,
    timestamp TIMESTAMP WITH TIME ZONE,
    objectid INTEGER,
    job_id CHARACTER VARYING,
    add_dttm TIMESTAMP WITH TIME ZONE,
    tycod CHARACTER VARYING,
    num_cust INTEGER,
    num_cust_restored INTEGER,
    toal_cust_affected INTEGER,
    off_dttm TIMESTAMP WITH TIME ZONE,
    est_rep_dttm TIMESTAMP WITH TIME ZONE,
    cause CHARACTER VARYING,
    dev_name CHARACTER VARYING,
    dev_id INTEGER,
    dev_type INTEGER,
    dev_type_name CHARACTER VARYING,
    event_status CHARACTER VARYING,
    dispatch_dttm TIMESTAMP WITH TIME ZONE,
    crew_status CHARACTER VARYING,
    est_rep_enddttm TIMESTAMP WITH TIME ZONE,
    circuit_est_dttm TIMESTAMP WITH TIME ZONE,
    circuit_est_enddttm TIMESTAMP WITH TIME ZONE,
    storm_mode CHARACTER VARYING,
    shape_length DOUBLE PRECISION,
    shape_area DOUBLE PRECISION,
    service_center CHARACTER VARYING,
    geometry public.geometry(Polygon,4326)
);"


cd /data
for file in /data/*.geojson; do

    fileBase=$(basename "$file" .geojson)
    fileTime=${fileBase##outage-}

    timestamp=$(date -d "$fileTime" +"%s")

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
FROM "$fileBase"
EOF
)

    # -overwrite
    #ogr2ogr -f "PostgreSQL" PG:"dbname=postgres user=postgres" -nln "$table"  -dialect sqlite -sql "$SQL" -lco GEOMETRY_NAME=geometry "$file"
    ogr2ogr -f "PostgreSQL" PG:"dbname=postgres user=postgres" -nln "$table"  -dialect sqlite -sql "$SQL" "$file"
done
psql -U postgres -c "SELECT * FROM $table LIMIT 1"
