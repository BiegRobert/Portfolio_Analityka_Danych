-- Task 1 -- O której godzinie najczęściej występują przejazdy z podwyższoną stawką? --

SELECT 
  HOUR(time_stamp) AS hour_of_day,
  COUNT(distinct id) AS count,
  ROUND(AVG(surge_multiplier), 2) AS avg_surge
FROM cab_rides_br
WHERE surge_multiplier <> 1
GROUP BY HOUR(time_stamp)
ORDER BY count desc

-- Task 2 -- Jaki wpływ mają opady deszczu na średnią cenę przejazdu? --

select
	floor(rain*20)/20 as floor_rain
	,round(avg(price), 2) as avg_price_by_rain
	-- ,count(distinct id) as count
from
	cab_rides_br crb
join weather_br wb 
	on
	crb.time_stamp = wb.time_stamp
	and
	crb.source = wb.location
where
floor(rain*20)/20 -- is not null
group by
	1
order by
	1

-- Task 3 -- Czy duże zachmurzenie (>75%) powoduje wzrost liczby przejazdów? --

select
	case
		when clouds > 0.75 then 'clouds > 75%'
		else 'clouds <= 0.75%'
	end as cloudiness,
	count(distinct id) as count
from
	cab_rides_br crb
join weather_br wb 
	on
	crb.time_stamp = wb.time_stamp
	and
	crb.source = wb.location
group by
	1

-- Task 4 -- Jak różnią się średnie ceny przejazdów między weekendami a dniami roboczymi? --

SELECT 
    CASE 
        WHEN WEEKDAY(time_stamp) IN (5, 6) THEN 'Weekend'
        ELSE 'Dzień roboczy'
    END AS typ_dnia,
    round(AVG(price), 2) AS srednia_cena
FROM 
    cab_rides_br
GROUP BY 
    typ_dnia;

-- Task 5 -- W której dzielnicy najczęściej występują przejazdy z podwyższyoną stawką? --

SELECT 
  source,
  COUNT(*) AS count,
  ROUND(AVG(surge_multiplier), 2) AS avg_surge
FROM cab_rides_br
WHERE surge_multiplier <> 1
GROUP BY source
ORDER BY count desc

-- Task 6 -- Jakie są średnie ceny przejazdów w zależności od wilgotności? --

select
	floor(humidity*20)/20 as floor_humidity
	,round(avg(price), 2) as avg_price_by_humidity
	-- ,count(distinct id) as count
from
	cab_rides_br crb
join weather_br wb 
	on
	crb.time_stamp = wb.time_stamp
	and
	crb.source = wb.location
group by
	1
order by
	1
	
-- Task 7 -- Czy ceny różnią się znacząco między Uberem a Lyftem przy podobnych dystansach (+/- 0,5 mili)? --

WITH
avg_price_Uber AS (
  SELECT
    FLOOR(distance*2)/2 AS floor_distance
    ,ROUND(AVG(price), 2) AS avg_price_Uber
  FROM
    cab_rides_br
  WHERE cab_type = 'Uber'
  GROUP BY 1
  ORDER BY 1
),
avg_price_Lyft AS (
  SELECT
    FLOOR(distance*2)/2 AS floor_distance
    ,ROUND(AVG(price), 2) AS avg_price_Lyft
  FROM
    cab_rides_br
  WHERE cab_type = 'Lyft'
  GROUP BY 1
  ORDER BY 1
)
SELECT 
  u.floor_distance,
  u.avg_price_Uber,
  l.avg_price_Lyft
FROM 
  avg_price_Uber u
JOIN 
  avg_price_Lyft l ON u.floor_distance = l.floor_distance
ORDER BY 
  u.floor_distance;

-- lub poprzez subquery

SELECT 
  u.floor_distance
  ,u.avg_price_Uber
  ,l.avg_price_Lyft
FROM 
  (
    SELECT
      FLOOR(distance*2)/2 AS floor_distance,
      ROUND(AVG(price), 2) AS avg_price_Uber
    FROM
      cab_rides_br
    WHERE 
      cab_type = 'Uber'
    GROUP BY 
      FLOOR(distance*2)/2
    ORDER BY 
      FLOOR(distance*2)/2
  ) u
JOIN 
  (
    SELECT
      FLOOR(distance*2)/2 AS floor_distance,
      ROUND(AVG(price), 2) AS avg_price_Lyft
    FROM
      cab_rides_br
    WHERE 
      cab_type = 'Lyft'
    GROUP BY 
      FLOOR(distance*2)/2
    ORDER BY 
      FLOOR(distance*2)/2
  ) l ON u.floor_distance = l.floor_distance
ORDER BY 
  u.floor_distance;

-- Task 8 -- W jakim dniu tygodnia najczęściej dochodzi do podwyższenia cen? --

SELECT 
	DAYOFWEEK(time_stamp) AS day_number
    ,count(*) as count
FROM cab_rides_br
where surge_multiplier > 1
group by 1
order by 2 desc

-- 

SELECT 
	DAYNAME(time_stamp) AS day_name
    ,count(*) as count
FROM cab_rides_br
where surge_multiplier > 1
group by 1
order by 2 desc

-- Task 9 -- Znajdź 3 najdroższe przejazdy z każdej dzielnicy (source) --

SELECT 
  source,
  price,
  most_expensive_rides
from
(
  SELECT 
    source,
    price,
    ROW_NUMBER() OVER (PARTITION BY source ORDER BY price DESC) AS most_expensive_rides
  FROM
    cab_rides_br
) AS ranked_rides
WHERE 
  most_expensive_rides <= 3
  
 -- Task 10 -- Znajdź przejazdy, które są rekordowo długie dla każdego typu przejazdu (product_name) --
  
 SELECT 
  name
  ,distance
  ,longest_rides
from
(
  SELECT 
    name
  	,distance,
    ROW_NUMBER() OVER (PARTITION BY name) AS longest_rides
  FROM
    cab_rides_br
) AS ranked_rides
WHERE 
  longest_rides <= 1
 order by 2 desc
 
 -- Task 11 -- Dane dla Uber wg dni tygodnia
 
WITH peak_hours AS (
    SELECT 
        DAYNAME(time_stamp) as day_name,
        HOUR(time_stamp) as hour_of_day,
        COUNT(*) as ride_count,
        ROW_NUMBER() OVER (PARTITION BY DAYNAME(time_stamp) ORDER BY COUNT(*) DESC) as rn
    FROM cab_rides_br
    WHERE cab_type = "Uber"
    GROUP BY DAYNAME(time_stamp), HOUR(time_stamp)
)
SELECT
    m.day_name,
    m.count_uber,
    m.average_price_uber,
    m.average_distance_uber,
    p.hour_of_day as peak_hour_uber
FROM (
    SELECT
        DAYNAME(time_stamp) AS day_name,
        count(*) as count_uber,
        round(avg(price), 2) as average_price_uber,
        round(avg(distance), 2) as average_distance_uber
    FROM cab_rides_br
    WHERE cab_type = "Uber"
    GROUP BY 1
    ORDER BY 2 DESC
) as m
JOIN peak_hours p ON m.day_name = p.day_name AND p.rn = 1

-- Task 12 -- Dane dla Lyft wg dni tygodnia

WITH peak_hours AS (
    SELECT 
        DAYNAME(time_stamp) as day_name,
        HOUR(time_stamp) as hour_of_day,
        COUNT(*) as ride_count,
        ROW_NUMBER() OVER (PARTITION BY DAYNAME(time_stamp) ORDER BY COUNT(*) DESC) as rn
    FROM cab_rides_br
    WHERE cab_type = "Lyft"
    GROUP BY DAYNAME(time_stamp), HOUR(time_stamp)
)
SELECT
    m.day_name,
    m.count_lyft,
    m.average_price_lyft,
    m.average_distance_lyft,
    p.hour_of_day as peak_hour_lyft
FROM (
    SELECT
        DAYNAME(time_stamp) AS day_name,
        count(*) as count_lyft,
        round(avg(price), 2) as average_price_lyft,
        round(avg(distance), 2) as average_distance_lyft
    FROM cab_rides_br
    WHERE cab_type = "Lyft"
    GROUP BY 1
    ORDER BY 2 DESC
) as m
JOIN peak_hours p ON m.day_name = p.day_name AND p.rn = 1
