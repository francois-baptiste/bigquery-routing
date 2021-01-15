#!/bin/bash

# How to run
# ./deploy --bucket <google-storage-bucket-path> --location <big-query-location> --dataset <big-query-dataset-id> --query_file_path <path-to-file> --project-id <project-id>
#
# e.g.:
# ./deploy.sh \
#   --gcp_file_path gs://bogdan-tools/geojson_path_finder.js \
#   --project_id 'data-science-229608' \
#   --dataset routing_us \
#   --query_file_path find_points_around_query_template.sql


gcp_file_path=${gcp_file_path}
dataset=${dataset}
project_id=${project_id}
location=${location}
query_file_path=${query_file_path}

# parse named parameters
while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
        # echo $1 $2 // Optional to see the parameter:value result
   fi

  shift
done

# clone repo
git clone --quiet https://github.com/xbogdan/geojson-path-finder.git
cd geojson-path-finder
git checkout feature/find-points-around

# install packages
npm install

# build
npm install webpack webpack-cli -g
webpack

# copy to gcp
gsutil cp dist/geojson_path_finder.js $gcp_file_path

# go back
cd ..

# clone big query routing
git clone --quiet https://github.com/xbogdan/bigquery-routing.git
cd bigquery-routing
git checkout feature/find-points-around
cd ..

# format query file
export DATASET="$dataset"
export PROJECT_ID="$project_id"
export BUCKET_FILE_PATH="$gcp_file_path"
envsubst < $query_file_path > query_file_new.sql

# deploy UDF function to BQ
# TODO add a directory of queries
bq --dataset_id=$dataset --location=$location query --use_legacy_sql=false < query_file_new.sql

# cleanup
rm -rf geojson-path-finder bigquery-routing
