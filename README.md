# Bigquery_shortest_path
Bigquery user-defined functions (UDFs) for pathfinding.
Find shortest path beetween to points through a network of Bigquery geography.

This project wraps [Per Liedman's GeoJSON Path Finder library](https://github.com/perliedman/geojson-path-finder/) to be run on Bigquery.

## Demo

This quick start use a webpack version of the [Per Liedman's GeoJSON Path Finder library with some tweaks](https://github.com/francois-baptiste/geojson-path-finder/) I personaly host on google clood storage and publicly available at gs://bigquery-geolib/geojson_path_finder.js


Open a Bigquery console, copy, paste and run [this query](query.sql).
This query calculate the shortest path between several USA cities using the railway network publicly available from BigQuery public datasets `bigquery-public-data.geo_us_boundaries`.

Unfortunately, the network is discontinuous in several places, thus preventing significant routing planning.


Reproduce what the path finding on the browser through the demo page https://francois-baptiste.github.io/Bigquery_shortest_path/.
