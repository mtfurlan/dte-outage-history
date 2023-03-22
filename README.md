# dte outage
Attempt to show DTE outages over time

DTE runs an arcgis server for it's outage information.
I've been scraping it for a while.

I would like to be able to answer questions like
* how often power goes out at a given location
* average outage duration for a given location
* what the worst/best places are for some defintion of best/worst

## Data
I didn't realize that the geojson was paginated till recently.
* 2021-11-08T15:36:27 to 2023-02-26T18:10:09: Truncated sometimes to 1k events.
* 2023-02-26T18:11:20 and onwards not truncated
* 2023-03-04T20:47:10 and onwards stored as geojson.tgz

If you want any of this data, please let me know (email in commits, or an issue, or whatever)

## next steps
* figure out how to re-assemble the geojson exports into postgis
* Actually do analysis

## Running
```
docker-compose up
docker exec -it dte-outage-history_postgres_1 /bin/bash -c "cd /data && ./try.sh"
```
go to http://localhost:8088

## Organization

* web
  * website to show stuff
* scrape
  * scraper for geojson, svg, png
* db
  * try to put scrape stuff in database

## Notes on DTE data
* png: https://outage.dteenergy.com/outageLayerImage.png
* svg: https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/export?dpi=96&transparent=true&format=svg&bbox=-9696759.515792493%2C5077501.619710184%2C-8868793.625407506%2C5533066.308289812&bboxSR=102100&imageSR=102100&size=1354%2C745&f=image
* geojson: https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/2/query?WHERE=OBJECTID%3E0&outFields=*&f=geojson

arcgis REST URL
* https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer
* export: https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/export
* query:  https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/query

https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/

Legend data:
* https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/legend
* https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/legend?f=json

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
