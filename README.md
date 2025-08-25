# dte outage
The goal is to analyze DTE outage data to to answer:
* how often power goes out at a given location
* average outage duration for a given location
* what the worst/best places are for some defintion of best/worst

## Data
Collecting SVG, PNG, and geojson
The SVG has some stupid bounds because I picked the wrong ones when starting and never noticed because I got geojson working

* 2021-11-08T15:36:27 to 2023-02-26T18:10:09: Truncated to 1k events, so not full data
* 2023-02-26T18:11:20 and onwards stored as geojson.tgz
* 2025-06-18T16:05:02-04:00: DTE started putting a 403 response from azure application gateway if it looks like a query, so I only have the svg and png output
* 2025-08-25T12:18:49-04:00: fixed geojson scraping, moved to 15 minutes because that's how often the data updates


If you want any of this data, please let me know (email in commits, or an issue,
or whatever)

### next steps
* figure out how to re-assemble the geojson exports into postgis
  * job_id is unique per job, we can track based on that
  * shape polygon can change
  * affected customer can change
  * "According to DTE's reply, the shape does not actually reflect the real-world coverage of the outage. It is an estimate about the "electricity customers" that the outages affect."
* Actually do analysis

## Analysis
* [Deep Learning-Based Weather-Related Power Outage Prediction with Socio-Economic and Power Infrastructure Data](https://arxiv.org/abs/2404.03115)

## What is actually in this repo
### `scrape`
This is the script I have running in a cronjob

There is also `fetch.sh` in the root of the repo to download data from my server
This should really be cleaned up but in the meantime I don't want to lose the
script

### everything else
can import a single snapshot into postgis, but no combining yet


There is a `docker-compose.yml` to orchistrate all this
* `db`: postgis db, with a script to import a single geojson data file
* `api`: expose the db
* `web`: call the api to get the geojson, and put the outage information on an
interactive map

#### Running
```
docker-compose up
docker exec -it dte-outage-history_postgres_1 /bin/bash -c "cd /data && ./try.sh"
```
go to http://localhost:8088

## Notes on DTE data
arcgis REST URL
* https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer

Documnetation:
* [query](https://developers.arcgis.com/rest/services-reference/enterprise/query-map-service-layer/): query into json
* [export](https://developers.arcgis.com/rest/services-reference/enterprise/export-map/): export image

Layers:
* all:
  * https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/layers
* ServiceAreaDetroitEdison (0)
  * outline of service area
  * https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/0/query?WHERE=OBJECTID%3E0&outFields=*&f=geojson
* ZipCodesDetroitEdison (1)
  * https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/1
* OutageAreas (2)
  * outages
  * https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/2
  * https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/2/query?WHERE=OBJECTID%3E0&outFields=*&f=geojson
* ELEDTE.RMS_SERVICECENTER_STORM_MODES (3)
  * looks like service station status?
  * https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/3
  * https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/3/query?WHERE=ID%3E0&outFields=*&f=pjson
