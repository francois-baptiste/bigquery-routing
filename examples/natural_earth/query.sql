WITH SOME_CITIES as (
select "New York" city, 40.6943 lat, -73.9249 lon union all
select "Los Angeles" city, 34.1139 lat, -118.4068 lon union all
select "Chicago" city, 41.8373 lat, -87.6862 lon union all
select "Miami" city, 25.7839 lat, -80.2102 lon union all
select "Dallas" city, 32.7936 lat, -96.7662 lon union all
select "Philadelphia" city, 40.0077 lat, -75.1339 lon union all
select "Houston" city, 29.7863 lat, -95.3889 lon union all
select "Atlanta" city, 33.7627 lat, -84.4224 lon union all
select "Washington" city, 38.9047 lat, -77.0163 lon union all
select "Boston" city, 42.3188 lat, -71.0846 lon union all
select "Phoenix" city, 33.5722 lat, -112.0891 lon union all
select "Seattle" city, 47.6211 lat, -122.3244 lon union all
select "San Francisco" city, 37.7562 lat, -122.443 lon union all
select "Detroit" city, 42.3834 lat, -83.1024 lon 
),
mynetwork as (
select array_agg(ST_GEOGFROMGEOJSON(GEOMETRY)) railways
FROM `replace_with_your_dataset.natural_earth_vector.ne_10m_railroads_north_america`
)
select a.city, b.city, `libjs4us.routing.geojson_path_finder`(railways, ST_GEOGPOINT(a.lon,a.lat), ST_GEOGPOINT(b.lon,b.lat))
FROM mynetwork , SOME_CITIES a, SOME_CITIES b
where a.city>b.city
