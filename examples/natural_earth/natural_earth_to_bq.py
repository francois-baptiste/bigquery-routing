import json
import sqlite3
import zipfile
import pandas as pd
import plpygis
import wget
from google.cloud import bigquery


def mylambda(x):
    try:
        return json.dumps(plpygis.Geometry(x).geojson)
    except plpygis.exceptions.WkbError:
        print(x)
        return None


print('Download data from naturalearth')

url = 'http://naciscdn.org/naturalearth/packages/natural_earth_vector.sqlite.zip'
wget.download(url, './natural_earth.zip')

zip = zipfile.ZipFile('./natural_earth.zip')
zip.extractall()

db = sqlite3.connect("./packages/natural_earth_vector.sqlite")
cursor = db.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
tables = cursor.fetchall()
client = bigquery.Client()
for i, table_name in enumerate(tables):
    table_name = table_name[0]
    table = pd.read_sql_query("SELECT * from %s" % table_name, db)
    try:
        table.GEOMETRY = table.GEOMETRY.apply(mylambda)
    except AttributeError:
        pass
    print("Uplading Table ", i, " : ", table_name)
    client.load_table_from_dataframe(table, 'natural_earth_vector.{}'.format(table_name)).result()
cursor.close()
db.close()
