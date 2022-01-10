#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

file=raw.geojson
base=${file%.geojson}
timestamp=1636414801
table=test_table

psql -U postgres -c "drop table if exists $table"
psql -U postgres -c "
CREATE TABLE IF NOT EXISTS $table (
    ogc_fid SERIAL PRIMARY KEY,
    timestamp timestamp,
    objectid integer,
    job_id character varying,
    add_dttm timestamp,
    tycod character varying,
    num_cust integer,
    num_cust_restored integer,
    toal_cust_affected integer,
    off_dttm timestamp,
    est_rep_dttm timestamp,
    cause character varying,
    dev_name character varying,
    dev_id integer,
    dev_type integer,
    dev_type_name character varying,
    event_status character varying,
    dispatch_dttm timestamp,
    crew_status character varying,
    est_rep_enddttm timestamp,
    circuit_est_dttm timestamp,
    circuit_est_enddttm timestamp,
    storm_mode character varying,
    shape_length double precision,
    shape_area double precision,
    service_center character varying,
    geometry public.geometry(Polygon,4326)
);"


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

# -overwrite
ogr2ogr -f "PostgreSQL" PG:"dbname=postgres user=postgres" -nln "$table"  -dialect sqlite -sql "$SQL" -lco GEOMETRY_NAME=geometry "$file"
psql -U postgres -c "SELECT * FROM $table LIMIT 1"
