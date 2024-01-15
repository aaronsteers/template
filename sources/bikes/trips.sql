SELECT *, 
extract(date from start_time) as start_date 
FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips` 
order by start_date desc 