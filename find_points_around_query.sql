CREATE TEMP FUNCTION geojson_find_points_around_(geojson STRING, startx FLOAT64, starty FLOAT64, max_cost FLOAT64) 
RETURNS STRING LANGUAGE js
OPTIONS (
  library=["gs://bigquery-geolib/geojson_path_finder.js"]
)
AS """
  var start = {type: "Feature", geometry: { coordinates:[startx, starty], type: "Point" }};
  var maxCost = max_cost;
  var pathFinder = new geojsonPathFinder(JSON.parse(geojson, { precision: 1e-3 }));
  var nodes = pathFinder.findPointsAround(start, maxCost);
  try {
    return JSON.stringify({ "coordinates": nodes, "type": "MultiPoint" });
  }
  catch (e) {
    return(null);
  }
""";


-- CREATE TEMP FUNCTION nearestpoint(mypoint GEOGRAPHY, mypoints array<GEOGRAPHY>) AS ((
--   With EXTRACTED_POINTS as (
--     SELECT SAFE.ST_GEOGFROMTEXT(CONCAT('POINT(', point, ')')) mypoints
--     FROM unnest(mypoints) geo_object,
--     UNNEST(REGEXP_EXTRACT_ALL(ST_ASTEXT(geo_object), r'[^,\(\)]+')) point WITH OFFSET pos
--     WHERE pos BETWEEN 1 AND ST_NUMPOINTS(geo_object)
--   )
--   SELECT ARRAY_AGG(a.mypoints ORDER BY ST_Distance(a.mypoints, mypoint) LIMIT 1)[ORDINAL(1)] as neighbor_id
--   FROM EXTRACTED_POINTS a 
-- ));


-- CREATE TEMP FUNCTION geojson_find_points_around(lines array<GEOGRAPHY>, start GEOGRAPHY, max_cost) AS ((
--   With
--     SOME_NETWORK as (
--     select concat('{"type": "FeatureCollection", "features": [{"type": "Feature","geometry":',string_agg(ST_ASGEOJSON(line),'},{"type":"Feature","geometry":'),"}]}") geojson,
--     nearestpoint(start,array_agg(line)) start_nearest,
--     nearestpoint(finish,array_agg(line)) finish_nearest
--     FROM unnest(lines) line
--   ),

--   OUTPUT as (
--     select geojson_path_finder_(geojson,ST_X(start_nearest),ST_Y(start_nearest),ST_X(finish_nearest),ST_Y(finish_nearest)) as myresult
--     from SOME_NETWORK
--   )

--   select 
--     STRUCT(CAST(JSON_EXTRACT(myresult, '$.weight') as FLOAT64) as weight,
--     safe.ST_GEOGFROMGEOJSON(JSON_EXTRACT(myresult, '$.geojson')) as path)
--   from OUTPUT
-- ));
