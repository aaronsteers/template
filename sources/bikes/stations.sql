SELECT 
    cast(cast(station_id as integer) as string) as station_id, 
    name, 
    status, 
    address 
FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations` 