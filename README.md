# Bigquery_shortest_path
Bigquery Javascript Pathfinding user-defined functions (UDFs): Find shortest path through a network of Bigquery geography

## Quick start

```sql
CREATE TEMP FUNCTION geojson_path_finder_(geojson STRING, startx FLOAT64, starty FLOAT64, finishx FLOAT64, finishy FLOAT64) RETURNS STRING LANGUAGE js
OPTIONS (library=["gs://bigquery-geolib/geojson_path_finder.js"]) AS """
var start = {type: "Feature",geometry:{coordinates:[startx,starty],type: "Point"}};
var finish = {type: "Feature",geometry:{coordinates:[finishx,finishy],type: "Point"}};
var pathFinder = new geojsonPathFinder(JSON.parse(geojson));
var myresult = pathFinder.findPath(start, finish);
try {
return JSON.stringify({"weight": myresult.weight, "geojson":{"type": "LineString", "coordinates":myresult.path}});
}
catch (e) {
  return(null)
}

""";
CREATE TEMP FUNCTION nearestpoint(mypoint GEOGRAPHY, mypoints array<GEOGRAPHY>) AS ((
With EXTRACTED_POINTS as (
SELECT SAFE.ST_GEOGFROMTEXT(CONCAT('POINT(', point, ')')) mypoints
FROM unnest(mypoints) geo_object,
UNNEST(REGEXP_EXTRACT_ALL(ST_ASTEXT(geo_object), r'[^,\(\)]+')) point WITH OFFSET pos
WHERE pos BETWEEN 1 AND ST_NUMPOINTS(geo_object)
)
SELECT ARRAY_AGG(a.mypoints ORDER BY ST_Distance(a.mypoints, mypoint) LIMIT 1)[ORDINAL(1)] as neighbor_id
FROM EXTRACTED_POINTS a 
));

CREATE TEMP FUNCTION geojson_path_finder(lines array<GEOGRAPHY>, start GEOGRAPHY, finish GEOGRAPHY) AS ((

With

SOME_NETWORK as (
select concat('{"type": "FeatureCollection", "features": [{"type": "Feature","geometry":',string_agg(ST_ASGEOJSON(line),'},{"type":"Feature","geometry":'),"}]}") geojson,
nearestpoint(start,array_agg(line)) start_nearest,
nearestpoint(finish,array_agg(line)) finish_nearest
FROM unnest(lines) line),

OUTPUT as (
select geojson_path_finder_(geojson,ST_X(start_nearest),ST_Y(start_nearest),ST_X(finish_nearest),ST_Y(finish_nearest)) myresult
from SOME_NETWORK)

select STRUCT(safe.ST_GEOGFROMGEOJSON(JSON_EXTRACT(myresult, '$.geojson')) as geog,
       CAST(JSON_EXTRACT(myresult, '$.weight') as FLOAT64) as weight,
       JSON_EXTRACT(myresult, '$.geojson') as geojson)
       from OUTPUT
));
   
CREATE TEMP FUNCTION create_random_point() AS ((
ST_GEOGPOINT( 180*(2*RAND()-1) , 90*(2*RAND()-1) )
));
       
CREATE TEMP FUNCTION create_random_points(num NUMERIC) AS ((
select array_agg(create_random_point()) mypoint
from unnest(GENERATE_ARRAY(1,num))
));


CREATE TEMP FUNCTION create_random_line(mypoints_ array<GEOGRAPHY>) AS ((
select ST_MakeLine(array_agg(mypoint_))
from unnest(mypoints_) mypoint_
where rand()<0.1
));

CREATE TEMP FUNCTION create_random_network(num NUMERIC) AS ((
WITH mypoints as (select create_random_points(100) mypoint)
select array_agg(create_random_line(mypoint)) as some_lines
from mypoints,unnest(GENERATE_ARRAY(1,num)) id
));

select geojson_path_finder(create_random_network(100), create_random_point(), create_random_point())
from unnest(GENERATE_ARRAY(1,30))
```

## From scratch

### Browserify geojson-path-finder

Use the following link from  "Browserify online" to browserify geojson-path-finder https://wzrd.in/standalone/geojson-path-finder@latest.

### Alternative
You can also pack geojson-path-finder and dependencies in a JS file using webpack.
