# dte outage
Attempt to show DTE outages over time

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
* ttps://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer
* xport: https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/export
* uery:  https://outagemap.serv.dteenergy.com/GISRest/services/OMP/OutageLocations/MapServer/query

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
