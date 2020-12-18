CREATE TEMP FUNCTION geojson_path_finder(geojson STRING, startx FLOAT64, starty FLOAT64, finishx FLOAT64, finishy FLOAT64) RETURNS STRING LANGUAGE js
OPTIONS (library=["gs://bigquery-geolib/geojson_path_finder.js"]) AS """
var start = {type: "Feature",geometry:{coordinates:[startx,starty],type: "Point"}};
var finish = {type: "Feature",geometry:{coordinates:[finishx,finishy],type: "Point"}};
function weightFn(a, b, props) {
    var d = distance(point(a), point(b)) * 1000,
        factor = 0.9,
        type = props.highway,
        forwardSpeed,
        backwardSpeed;
    if (props.maxspeed) {
        forwardSpeed = backwardSpeed = Number(props.maxspeed);
    } else {
        var linkIndex = type.indexOf('_link');
        if (linkIndex >= 0) {
            type = type.substring(0, linkIndex);
            factor *= 0.7;
        }
        forwardSpeed = backwardSpeed = highwaySpeeds[type] * factor;
        if (!forwardSpeed) {
            unknowns[type] = true;
        }
    }
    if (props.oneway && props.oneway !== 'no' || props.junction && props.junction === 'roundabout') {
        backwardSpeed = null;
    }
    return {
        forward: forwardSpeed && (d / (forwardSpeed / 3.6)),
        backward: backwardSpeed && (d / (backwardSpeed / 3.6)),
    };
}
var pathFinder = new geojsonPathFinder(JSON.parse(geojson, {precision: 1e-9,weightFn: weightFn}));
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

WITH SOME_CITIES as (
select "Point A" city, ST_GEOGPOINT(11.99,57.740) point union all
select "Point B" city, ST_GEOGPOINT(11.90,57.68)
),

NETWORK as (
select
array_agg(ST_GEOGFROMGEOJSON(JSON_EXTRACT(features, '$.geometry'))) geography,
concat('{"type": "FeatureCollection", "features": [',string_agg(features,','),"]}") geojson
from temp.network_demo
),
RESULT as (select a.city start, b.city dest, geojson_path_finder(geojson,
ST_X(nearestpoint(a.point,geography)),
ST_Y(nearestpoint(a.point,geography)),
ST_X(nearestpoint(b.point,geography)),
ST_Y(nearestpoint(b.point,geography))
) myresult
from NETWORK, SOME_CITIES a, SOME_CITIES b
where a.city>b.city)
select start, dest, JSON_EXTRACT(myresult, '$.weight') time_in_min, JSON_EXTRACT(myresult, '$.geojson') geojson
from RESULT
