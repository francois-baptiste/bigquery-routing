CREATE OR REPLACE FUNCTION `$PROJECT_ID.$DATASET.geojson_find_points_around`(geojson STRING, startx FLOAT64, starty FLOAT64, max_cost FLOAT64) 
RETURNS STRING LANGUAGE js
OPTIONS (
  library=["$BUCKET_FILE_PATH"]
)
AS """
  var start = {type: "Feature", geometry: { coordinates:[startx, starty], type: "Point" }};
  var maxCost = max_cost;
  var pathFinder = new geojsonPathFinder(JSON.parse(geojson));

  var nodes = pathFinder.findPointsAround(start, maxCost);
  try {
    return JSON.stringify({
      type: "FeatureCollection",
      features: [
        {
          type: "Feature",
          geometry: {
            type: "MultiPoint",
            coordinates: nodes
          }
        }
      ]
    });
  }
  catch (e) {
    return(null);
  }
""";

-- USAGE EXAMPLE
-- select  
--    `data-science-229608.routing_us.geojson_find_points_around`(concat('{"type": "FeatureCollection", "features": [{"type": "Feature","geometry":', string_agg(line, '},{"type":"Feature","geometry":'),"}]}"), -1.028, 46.56, 200 )
-- from `data-science-229608.routing_us.france_network`;