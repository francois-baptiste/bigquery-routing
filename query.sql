CREATE TEMP FUNCTION geojson_path_finder_(geojson STRING, startx FLOAT64, starty FLOAT64, finishx FLOAT64, finishy FLOAT64) RETURNS STRING LANGUAGE js
OPTIONS (library=["gs://bigquery-geolib/geojson_path_finder.js"]) AS """
var start = {type: "Feature",geometry:{coordinates:[startx,starty],type: "Point"}};
var finish = {type: "Feature",geometry:{coordinates:[finishx,finishy],type: "Point"}};
var pathFinder = new geojsonPathFinder(JSON.parse(geojson, { precision: 1e-3 }));
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

select STRUCT(CAST(JSON_EXTRACT(myresult, '$.weight') as FLOAT64) as weight,
       safe.ST_GEOGFROMGEOJSON(JSON_EXTRACT(myresult, '$.geojson')) as path)
       from OUTPUT

));

   
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


select a.city, b.city, geojson_path_finder(railways, ST_GEOGPOINT(a.lon,a.lat), ST_GEOGPOINT(b.lon,b.lat)) shortest_path
FROM mynetwork , SOME_CITIES a, SOME_CITIES b
where a.city>b.city
