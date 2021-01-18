CREATE OR REPLACE FUNCTION `$PROJECT_ID.$DATASET.find_points_around_from_geojson`(geojson STRING, startx FLOAT64, starty FLOAT64, max_cost FLOAT64) 
RETURNS STRING LANGUAGE js
OPTIONS (
  library=["$BUCKET_FILE_PATH"]
)
AS """
  var start = {type: "Feature", geometry: { coordinates: [startx, starty], type: "Point" }};
  var maxCost = max_cost;
  var pathFinder = new geojsonPathFinder(JSON.parse(geojson));

  var nodes = pathFinder.findPointsAround(start, maxCost);
  try {
    return JSON.stringify({
      type: "MultiPoint",
      coordinates: nodes
    });
  }
  catch (e) {
    return(null);
  }
""";

CREATE OR REPLACE FUNCTION `$PROJECT_ID.$DATASET.nearestpoint`(mypoint GEOGRAPHY, mypoints array<GEOGRAPHY>) AS ((
  WITH EXTRACTED_POINTS AS (
    SELECT SAFE.ST_GEOGFROMTEXT(CONCAT('POINT(', point, ')')) mypoints
    FROM unnest(mypoints) geo_object,
      UNNEST(REGEXP_EXTRACT_ALL(ST_ASTEXT(geo_object), r'[^,\(\)]+')) point WITH OFFSET pos
    WHERE pos BETWEEN 1 AND ST_NUMPOINTS(geo_object)
  )
  SELECT ARRAY_AGG(a.mypoints ORDER BY ST_Distance(a.mypoints, mypoint) LIMIT 1)[ORDINAL(1)] as neighbor_id
  FROM EXTRACTED_POINTS a
));

-- 
CREATE OR REPLACE FUNCTION `$PROJECT_ID.$DATASET.find_points_around`(lines array<GEOGRAPHY>, start GEOGRAPHY, max_cost FLOAT64) AS ((
  WITH SOME_NETWORK AS (
    SELECT concat('{"type": "FeatureCollection", "features": [{"type": "Feature","geometry":', string_agg(ST_ASGEOJSON(line), '},{"type":"Feature","geometry":'), "}]}") geojson,
    `$PROJECT_ID.$DATASET.nearestpoint`(start, array_agg(line)) start_nearest,
    FROM unnest(lines) line
  ),
  OUTPUT AS (
    SELECT `$PROJECT_ID.$DATASET.find_points_around_from_geojson`(geojson, ST_X(start_nearest), ST_Y(start_nearest), max_cost) myresult
    FROM SOME_NETWORK
  )

  SELECT * FROM OUTPUT
));

CREATE OR REPLACE FUNCTION `$PROJECT_ID.$DATASET.get_isodistance_polygon`(lines array<GEOGRAPHY>, start GEOGRAPHY, max_cost FLOAT64) AS ((
  SELECT ST_CONVEXHULL(ST_GEOGFROMGEOJSON(`$PROJECT_ID.$DATASET.find_points_around`(lines, start, max_cost)))
));
