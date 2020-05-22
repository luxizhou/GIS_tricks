#!/usr/bin/env python

import geopandas as gpd
import pandas as pd
from geopandas.tools import geocode
from geopy.exc import GeocoderTimedOut
from fiona.crs import from_epsg
import pycrs
import time

# Read in addresses
#df = pd.read_csv('shopping_centers.txt',sep=';')
df = pd.read_csv('Addresses.txt',sep=';')

## Method 1: Use Open Street Map Nominatim
## Calling to the Nominatim geocoder somtimes returns error message "GeocoderTimedOut" and the solution is to try again and again. Therefore I wrote the function do_geocode to do multiple calls. 
## I found trying 30 times (max_att=30) with a waiting interval 5 seconds (sec=5) returns lat/lon for all my test addresses successfully. One could modify the attemps and waiting time for optimized 
## execution time.  

max_att = 30
sec = 5
def do_geocode(row, attempt=1, max_attempts=max_att):
    try:
        return geocode(row['Address'],provider='nominatim')
    except GeocoderTimedOut:
        time.sleep(sec)
        if attempt<=max_attempts:
            return do_geocode(row, attempt=attempt+1, max_attempts=max_att)
        raise idx
    return

# Geocode addresses
geo = gpd.GeoDataFrame()
for idx,row in df.iterrows():
    res = do_geocode(df.loc[idx,:])
    if idx == 0:
        geo = res.copy()
    else:
        geo = geo.append(res,ignore_index=True)

# Join original dataset
geo = geo.join(df)

# Set projection
proj4_txt = pycrs.parse.from_epsg_code(4326).to_proj4()
geo['geometry'] = geo['geometry'].to_crs(proj4_txt)
geo.crs = proj4_txt

# Output file to shapefile
geo.to_file('Nominatim_results.shp')
####################################################################################################################################################################################
## Method 2: Use Google Geocoding API 
## An API key is needed use the Google geocoder. Guides to get an API key: https://developers.google.com/maps/documentation/geocoding/get-api-key

key = 'your key here'
geo = geocode(df.Address,provider='GoogleV3',api_key=key)

# Set projection
proj4_txt = pycrs.parse.from_epsg_code(4326).to_proj4()
geo['geometry'] = geo['geometry'].to_crs(proj4_txt)
geo.crs = proj4_txt

# Output file to shapefile
geo.to_file('Google_result.shp')
