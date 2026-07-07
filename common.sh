#!/bin/bash
#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

#IMPORT_DIR=${IMPORT_DIR:-$DIR/data/import}
#PROCESSED_DIR=${PROCESSED_DIR:-$DIR/data/processed}

IMPORT_DIR=${IMPORT_DIR:-/data/import}
PROCESSED_DIR=${PROCESSED_DIR:-/data/processed}

DATE_FORMAT="%Y-%m-%d--%H-%M-%S%z"
# parse with strptime -i "$DATE_FORMAT" "$date"
# output with date +"$DATE_FORMAT" -d "$date"


export IMPORT_DIR PROCESSED_DIR DATE_FORMAT

