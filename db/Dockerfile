FROM postgis/postgis:18-3.6

RUN apt-get update && apt-get install -y \
    gdal-bin \
    jq \
    && rm -rf /var/lib/apt/lists/*

