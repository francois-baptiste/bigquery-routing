import json
import pandas as pd
from google.cloud import bigquery

print('Upload geojson-path-finder network demo to Bigquery')

with open('network.json') as json_file:
    df=pd.DataFrame([json.dumps(v) for v in json.load(json_file)['features']])
df.columns=['features']
bigquery.Client().load_table_from_dataframe(df,'temp.network_demo').result()
