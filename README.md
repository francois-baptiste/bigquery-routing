# Bigquery routing
Bigquery user-defined functions (UDFs) for routing/path finding.
Find shortest path through a network of Bigquery geography.

This project wraps [Per Liedman's GeoJSON Path Finder library](https://github.com/perliedman/geojson-path-finder/) to be run on Bigquery.

## Off-the-Shelf Demo
For this demo we use an webpack version of the [Per Liedman's GeoJSON Path Finder library with some tweaks](https://github.com/francois-baptiste/geojson-path-finder/blob/webpack/geojson_path_finder.js) that I host for you on publicly GCS at gs://bigquery-geolib/geojson_path_finder.js. I also host routing UDFs on US and EU Bigquery dataset publicly available at `libjs4us.routing` and  `libjs4eu.routing`.

We also use one of the few network available from BigQuery public dataset: `bigquery-public-data:geo_us_boundaries.railways`. Unfortunately, the network is discontinuous in several places, thus preventing significant routing planning. If you want great railroads network datasets, I advise you to look at the [Natural Earth dataset](#playing-with-natural-earth-dataset).

Open a Bigquery console, copy, paste and run this query:
```sql
WITH SOME_CITIES as (
select "OSKALOOSA " city, 41.290438 lat, -92.638499 lon union all 
select "NEW SHARON " city, 41.470103 lat, -92.650924 lon union all
select "GRINELL " city, 41.738154 lat, -92.724915 lon union all
select "MARSCHALLTOWN " city, 42.049467 lat, -92.908037 lon union all
select "COLO " city, 42.014482 lat, -93.318599 lon union all
select "DES MOINES " city, 41.619549 lat, -93.598022 lon
),
mynetwork as (
select array_agg(railway_geom) railways
FROM `bigquery-public-data.geo_us_boundaries.railways`
where full_name="Union Pacific RR" and ST_DISTANCE(railway_geom, ST_GEOGPOINT(-93,42)) <100000
)
select a.city, b.city, libjs4us.routing.geojson_path_finder(railways, ST_GEOGPOINT(a.lon,a.lat), ST_GEOGPOINT(b.lon,b.lat)) shortest_path
FROM mynetwork , SOME_CITIES a, SOME_CITIES b
where a.city>b.city
```
This query returns for each couple of cities the weight (the distance in this case) and the path of the shortest route through the rail network:

![demo](./img/demo.png)


## Playing with Natural Earth dataset
I write a python script intended to be run on the Google Cloud Shell to load [Natural Earth dataset](https://www.naturalearthdata.com/).
You can get the python script [here](/examples/natural_earth/natural_earth_to_bq.py).

It creates a Bigquery dataset named `natural_earth_vector` containing a lot of tables with geography of states, provinces, boundary, countries, regions, rivers, lakes , islands, ocean, populated area, ice shelves, coastline, parks, airports, ports, railroads, roads...

You can now test the routing algorithm at a larger scale over the neatly connected natural earth railroads database using this [here](/examples/natural_earth/query.sql).

You can reproduce the path search logic directly on your browser using the same JS library via the Per Liedman's [demo page adapted for the circumstance](https://francois-baptiste.github.io/bigquery-routing/).

## Weight functions

By default, the _cost_ of going from one node in the network to another is determined simply by
the geographic distance between the two nodes. This means that, by default, shortest paths will be found.
You can however override this by providing a cost calculation function through the `weightFn` option when calling the JS lib on Bigquery as shown above.

The [live demo](https://francois-baptiste.github.io/geojson-path-finder/) around Gothenburg proposed by Per Liedman uses the speed limit extacted from OSM to choose the fastest route in terms of time.
You can load the graph to bigquery from google cloud shell using this python [script](/examples/custom_weightFn/upload_network_to_bigquery.py) and run this demo on bigquery using this [query](/examples/custom_weightFn/query.sql).

You can download the network to bigquery 
## Playing with OpenStreetMap data snapshot accessible from BigQuery

TODO
