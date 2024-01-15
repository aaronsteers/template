---
title: Austin Bikes Dashboard
---

<BigValue 
  data={trip_kpis} 
  value=duration 
  comparison=duration_growth_pct 
  comparisonTitle='Y/y' 
  title="Duration" fmt='num0' 
  comparisonFmt='pct1'/>

<BigValue 
  data={trip_kpis} 
  value=n_trips 
  comparison=trips_growth_pct 
  comparisonTitle='Y/y' 
  title="Trips" 
  fmt='num0' 
  comparisonFmt='pct1'/>

<BigValue 
  data={trip_kpis} 
  value=avg_duration 
  comparison=avg_duration_growth_pct 
  comparisonTitle='Y/y' 
  title="Avg. Duration" 
  fmt='num0' 
  comparisonFmt='pct1' />

Riders have completed <Value data={trip_kpis} column=n_trips fmt='num0'/> trips in <Value data={trip_kpis} fmt='mmm'/>, <Value data={trip_kpis} column=trips_growth_pct /> over 12 months prior.

```sql trip_kpis

  select
    date_trunc('month', start_date) as month,
    extract(year from start_date) as year,
    extract(month from start_date) as month_of_year,
    lag(month, 12) over(order by month) as lagged_month,
    count(*) as n_trips,
    count(*) filter (where end_station_name = 'Stolen') as theft,
    sum(duration_minutes) as duration,
    duration/n_trips as avg_duration,
    n_trips/lag(n_trips, 12) over(order by month) - 1 as trips_growth_pct,
    duration/lag(duration, 12) over(order by month) - 1 as duration_growth_pct,
    avg_duration/lag(avg_duration, 12) over(order by month) - 1 as avg_duration_growth_pct,
    n_trips - lag(n_trips, 12) over(order by month) as abs_trips_growth,
  from bikes.trips
  group by 1,2,3
  order by 1 desc
```

```sql monthly_trips_by_avg_duration
select * from ${trip_kpis} order by avg_duration desc
```

```sql monthly_trips_by_count
select * from ${trip_kpis} order by n_trips desc
```

{JSON.stringify(data.current_month)}

<BarChart
  data={trip_kpis}
  x=month
  xFmt='mmm yy'
  y=duration 
  title="Total Trip Duration Trips" 
  yAxisTitle="Minutes Riding">
<ReferenceLine x='2018-02-15' label="Ride Free Campaign" hideValue=true/>
</BarChart>

<Tabs>

  <Tab label='Trips'>

<BarChart
    data={trip_kpis}
    x=month
    xFmt='mmm yy'
    y=n_trips 
    title="Monthly Trips" 
    yAxisTitle=Trips
    fillColor='lightgray'
  />

Most trips were taken in <Value data={monthly_trips_by_count} column=month row=0 fmt='mmm yy' />, with <Value data={monthly_trips_by_count} column=n_trips row=0 fmt='num0' /> trips.

  </Tab>

  <Tab label='Avg. Duration'>

<BarChart
    data={trip_kpis}
    x=month
    xFmt='mmm yy'
    y=avg_duration 
    title="Average Trip Duration" 
    yAxisTitle=Minutes
    fillColor='lightgray'
  />

The longest trips are in <Value data={monthly_trips_by_avg_duration} column=month row=0 fmt='mmm yy' />, with an average duration of <Value data={monthly_trips_by_avg_duration} column=avg_duration row=0 fmt='num0' /> minutes.

  </Tab>
</Tabs>

# Growth by Subscriber Type

Of the <Value data={trip_kpis} column=abs_trips_growth/> change in trips, <Value data={monthly_subscriber_type_growth} column=cumulative_pct_of_growth row={monthly_subscriber_type_growth.length-1} fmt='pct' /> is attributable to {monthly_subscriber_type_growth.length} [subscriber types](/paramaterized_pages/subscriber-types):

```sql subscriber_growth
select
      subscriber_type,
      date_trunc('month', start_date) as month,
      count(*) as n_trips,
      n_trips - coalesce(lag(n_trips, 12) over(partition by subscriber_type order by month),0) as abs_trips_growth,
      n_trips/lag(n_trips, 12) over(partition by subscriber_type order by month) - 1 as trips_growth_pct,
    from bikes.trips
    group by 1,2
    order by 2 desc, 4 desc
```
```sql global_trip_kpis
    select
      month as global_month,
      abs_trips_growth as global_absolute_trip_growth
    from ${trip_kpis}
```

```sql pareto
select
      month,
      subscriber_type,
      'detail/subscriber-types/' || subscriber_type as link,
      n_trips,
      abs_trips_growth,
      trips_growth_pct,
      abs_trips_growth/global_absolute_trip_growth as pct_of_growth,
      sum(pct_of_growth) over(partition by month order by pct_of_growth desc) as cumulative_pct_of_growth
    from ${subscriber_growth}, ${global_trip_kpis},
    where month = global_month
```



```sql monthly_subscriber_type_growth
  select * from ${pareto}
  where cumulative_pct_of_growth <= 0.95 AND pct_of_growth > 0 AND month = ${inputs.current_month}
```



<DataTable data={monthly_subscriber_type_growth}>
  <Column id=subscriber_type />
  <Column id=n_trips title="Trips this month" fmt='num0'/>
  <Column id=abs_trips_growth title="Y/y Trips" fmt='num0'/>
  <Column id=trips_growth_pct title="Y/y %" fmt='pct'/>
  <Column id=pct_of_growth title="Share of Change (%)" fmt='pct'/>
</DataTable>

```sql trend_in_top_subscribers

  select
    subscriber_type,
    date_trunc('month', start_date) as month,
    count(*) as n_trips,
  from bikes.trips
  group by 1,2
  order by 2 desc

```

{#each monthly_subscriber_type_growth as subscriber_type}

## {subscriber_type.subscriber_type}

<BarChart  
 data={trend_in_top_subscribers.filter(d => d.subscriber_type === subscriber_type.subscriber_type)}
x=month
y=n_trips
yAxisTitle=Trips
yFmt='num0'
title={`Trips by ${subscriber_type.subscriber_type} subscribers` }
/>

{/each}

```sql current_month

select max(month) from ${trip_kpis}

```

<Details title="Footnotes">

## Total Trip Duration

- Total trip duration is the sum of all trip durations in a given month.
- Trip duration is measured in minutes from the bike departing a station to arriving at another station, or being classified as stolen.
- Trip duration is always rounded to the next largest minute. A trip of one second is counted as one minute.

## Number of Trips

- Number of trips is the count of all trips in a given month.
- A trip is counted when a bike is removed from a station.

## Average Trip Duration

- Average trip duration is the total trip duration divided by the number of trips in a given month.
- Average trip duration is measured in minutes.

</Details>


```sql orders
select * from orders limit 2
```

{JSON.stringify(orders)}
