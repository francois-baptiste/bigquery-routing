# Bigquery_shortest_path
Bigquery Javascript Pathfinding user-defined functions (UDFs): Find shortest path through a network of Bigquery geography

## Quick start

```sql
CREATE TEMP FUNCTION geojson_path_finder_(geojson STRING, startx FLOAT64, starty FLOAT64, finishx FLOAT64, finishy FLOAT64) RETURNS STRING LANGUAGE js
OPTIONS (library=["gs://bigquery-geolib/geojson-path-finder.js"]) AS """
var start = {type: "Feature",geometry:{coordinates:[startx,starty],type: "Point"}};
var finish = {type: "Feature",geometry:{coordinates:[finishx, finishy],type: "Point"}};
var pathFinder = new geojsonPathFinder(JSON.parse(geojson));
var myresult = pathFinder.findPath(start, finish);
return JSON.stringify({"weight": myresult.weight, "geojson":{"type": "LineString", "coordinates":myresult.path}});
""";

CREATE TEMP FUNCTION geojson_path_finder(geojson STRING, start GEOGRAPHY, finish GEOGRAPHY) AS (
STRUCT(safe.ST_GEOGFROMGEOJSON(JSON_EXTRACT(geojson_path_finder_(geojson,ST_X(start),ST_Y(start),ST_X(finish),ST_Y(finish)), '$.geojson')) as shortest_path,
       CAST(JSON_EXTRACT(geojson_path_finder_(geojson,ST_X(start),ST_Y(start),ST_X(finish),ST_Y(finish)), '$.weight') as FLOAT64) as weight,
       JSON_EXTRACT(geojson_path_finder_(geojson,ST_X(start),ST_Y(start),ST_X(finish),ST_Y(finish)), '$.geojson') as geojson)
);



With SOME_POINTS as (SELECT station_id, ST_GEOGPOINT( longitude , latitude ) location FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`),
SOME_LINESTRINGS as (
select ST_MakeLine(array_agg(station.location)) as some_line
from SOME_POINTS station
group by mod(station.station_id, 7)
union all
select ST_MakeLine(array_agg(station.location)) as some_line
from SOME_POINTS station
group by mod(station.station_id, 13)
union all
select ST_MakeLine(array_agg(station.location)) as some_line
from SOME_POINTS station
group by mod(station.station_id, 17)),

SOME_NETWORK as (
select concat('{"type": "FeatureCollection", "features": [{"type": "Feature","geometry":',string_agg(ST_ASGEOJSON(some_line),'},{"type":"Feature","geometry":'),"}]}") my_network
from SOME_LINESTRINGS),

RESULT as (
select station1.station_id station_id1, station2.station_id station_id2, geojson_path_finder(my_network, station1.location, station2.location) myresult
from SOME_NETWORK, SOME_POINTS station1, SOME_POINTS station2
where st_distance(station1.location,station2.location)>10 
)

Select station_id1, station_id2, myresult.shortest_path, myresult.weight  from RESULT
```

## From scratch

### Browserify geojson-path-finder

Use the following link from  "Browserify online" to browserify geojson-path-finder https://wzrd.in/standalone/geojson-path-finder@latest.

### Alternative
You can also pack geojson-path-finder and dependencies in a JS file using webpack.
