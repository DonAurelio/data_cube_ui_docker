#!/bin/bash

echo "Creating database for Datacube..."
# check, if database already exists and create if not
if docker exec datacubeuidocker_db_1 psql -U datacube -l | grep '^\sodc' > /dev/null; then
    echo "Database 'odc' already exists."
else
    echo "Database 'odc' does not exist, creating it now..."
    # TODO: find a way to get rid of the password prompt
    docker exec -ti datacubeuidocker_db_1 createdb -U datacube -h db -p 5432 odc || exit 1
fi
echo "Initializing Datacube system..."
docker exec datacubeuidocker_www_1 datacube -v system init

echo "Preparing file storage for Datacube and Datacube UI..."

# NOTE: configure the location of your datacube directory here, where original
# data, ingested data and results of the UI are/should be stored
declare -r DATA_HOME="/data/docker/data_cube_ui_docker/datacube"

if [[ -z "$DATA_HOME" ]]; then
    echo "Error: No Datacube directory given." >> /dev/stderr
    exit 1
elif [[ ! -d "$DATA_HOME" ]]; then
    echo "Error: DATA_HOME does not exist or is not a directory." >> /dev/stderr
    exit 1
fi

mkdir -p "$DATA_HOME"/{original_data,ingested_data,ui_results,ui_results_temp}
mkdir -p "$DATA_HOME/ui_results"/{custom_mosaic,fractional_cover,tsm,water_detection,slip}

echo "Datacube system and directories prepared. You can run the ingestion scripts now."

echo "Creating superuser"
docker exec -ti datacubeuidocker_www_1 python3 manage.py createsuperuser

echo "Loading initial demo data"
docker exec datacubeuidocker_www_1 python3 manage.py loaddata db_backups/init_database.json
