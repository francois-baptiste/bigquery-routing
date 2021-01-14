#!/bin/bash

# How to run
# ./deploy --bucket <google-storage-bucket-path> --location <big-query-location> --dataset <big-query-dataset-id> --query_file <path-to-file> --project-id <project-id>

gcp_file_path=${gcp_file_path}
dataset=${dataset}
project_id=${project_id}
location=${location}
query_file=${query_file}

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
git clone https://github.com/xbogdan/geojson-path-finder.git
cd geojson-path-finder
git checkout feature/find-points-around

# install packages
npm install

# build
npm install webpack webpack-cli -g
webpack

# copy to gcp
gsutil cp dist/geojson_path_finder.js $gcp_file_path

git clone https://github.com/xbogdan/bigquery-routing.git
cd bigquery-routing
git checkout feature/find-points-around

# format query file
export DATASET="$dataset"
export PROJECT_ID="$project_id"
export BUCKET_FILE_PATH="$gcp_file_path"
envsubst < $query_file > query_file_new.sql

# deploy UDF function to BQ
# TODO add a directory of queries
bq --dataset_id=$dataset --location=$location query --use_legacy_sql=false < query_file_new.sql

# cleanup
cd ..
rm -rf geojson-path-finder bigquery-routing

