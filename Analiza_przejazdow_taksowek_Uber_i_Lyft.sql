-- ############################################################################
-- # Portfolio Analityka Danych - Analiza przejazdów taksówek Uber i Lyft #
-- ############################################################################
-- # Autor: Robert Bieg
-- # Data: 03-05-2025
-- ############################################################################

-- ############################################################################
-- # Zadanie 1: Analiza godzin z podwyższoną stawką
-- ############################################################################
-- # Cel: Identyfikacja godzin, w których najczęściej występują przejazdy 
-- # z podwyższoną stawką (surge pricing).
-- #
-- # Wartość biznesowa: 
-- # - Pozwala zidentyfikować szczyty popytu
-- # - Umożliwia lepsze zrozumienie wzorców konsumenckich
-- # - Wspiera optymalizację strategii cenowej
-- ############################################################################

SELECT 
  -- Ekstrakcja godziny z timestampu
  HOUR(time_stamp) AS hour_number,
  -- Konwersja do formatu godzinowego dla lepszej czytelności
  MAKETIME(HOUR(time_stamp), 0, 0) AS hour_of_day,
  -- Segregacja liczby przejazdów według dostawcy
  SUM(CASE WHEN cab_type = 'Uber' THEN 1 ELSE 0 END) AS uber_count,
  SUM(CASE WHEN cab_type = 'Lyft' THEN 1 ELSE 0 END) AS lyft_count,
  -- Całkowita liczba przejazdów
  count(*) as total_count
FROM cab_rides_br
-- Filtrowanie tylko przejazdów z mnożnikiem podwyższonej ceny
WHERE surge_multiplier <> 1
GROUP BY 
  HOUR(time_stamp), 
  MAKETIME(HOUR(time_stamp), 0, 0)
ORDER BY 
  HOUR(time_stamp);


-- ############################################################################
-- # Zadanie 2: Wpływ opadów deszczu na średnią cenę przejazdu
-- ############################################################################
-- # Cel: Zbadanie korelacji między poziomem opadów deszczu a średnią ceną 
-- # przejazdów.
-- #
-- # Wartość biznesowa: 
-- # - Wykazanie wpływu warunków pogodowych na popyt i ceny
-- # - Wsparcie prognozowania zapotrzebowania
-- # - Wsparcie strategii dynamicznego ustalania cen
-- ############################################################################

SELECT
  -- Kategoryzacja poziomu opadów po przeliczeniu z cali na milimetry (przedziały co 0.05 mm)
  floor(rain * 25.4 * 20) / 20 AS floor_rain_mm,

  -- Obliczenie średniej ceny przejazdu dla każdego przedziału opadów w milimetrach
  round(avg(price), 2) AS avg_price_by_rain

FROM
  cab_rides_br crb

-- Połączenie danych o przejazdach z odpowiadającymi im danymi pogodowymi
JOIN weather_br wb 
  ON crb.time_stamp = wb.time_stamp
  AND crb.source = wb.location

-- Wykluczenie rekordów bez danych o opadach
WHERE rain IS NOT NULL

-- Grupowanie wyników według przeliczonego i zaokrąglonego poziomu opadów
GROUP BY floor_rain_mm

-- Sortowanie wyników rosnąco według poziomu opadów
ORDER BY floor_rain_mm;


-- ############################################################################
-- # Zadanie 3: Wpływ zachmurzenia na liczbę przejazdów
-- ############################################################################
-- # Cel: Sprawdzenie, czy duże zachmurzenie (>75%) powoduje wzrost liczby 
-- # przejazdów.
-- #
-- # Wartość biznesowa: 
-- # - Insight na temat wpływu zachmurzenia na zachowania konsumentów
-- # - Optymalizacja alokacji zasobów w określonych warunkach pogodowych
-- # - Wsparcie decyzji operacyjnych
-- ############################################################################

SELECT
  -- Podział danych na dwie kategorie zachmurzenia
  CASE
    WHEN clouds > 0.75 THEN 'clouds > 75%'
    ELSE 'clouds <= 75%'
  END AS cloudiness,
  -- Zliczanie unikalnych przejazdów w każdej kategorii
  COUNT(DISTINCT id) AS count
FROM
  cab_rides_br crb
-- Połączenie danych przejazdów z danymi pogodowymi
JOIN weather_br wb 
  ON crb.time_stamp = wb.time_stamp
  AND crb.source = wb.location
GROUP BY 1;


-- ############################################################################
-- # Zadanie 4: Porównanie cen przejazdów w weekendy i dni robocze
-- ############################################################################
-- # Cel: Zbadanie różnic w średnich cenach przejazdów między weekendami 
-- # a dniami roboczymi.
-- #
-- # Wartość biznesowa: 
-- # - Zrozumienie wzorców cenowych w zależności od dnia tygodnia
-- # - Wsparcie strategii cenowej
-- # - Optymalizacja planowania zasobów
-- ############################################################################

SELECT 
  -- Kategoryzacja dni na weekendy i dni robocze
  CASE 
    WHEN WEEKDAY(time_stamp) IN (5, 6) THEN 'Weekend'
    ELSE 'Dzień roboczy'
  END AS typ_dnia,
  -- Obliczenie średniej ceny dla każdej kategorii
  ROUND(AVG(price), 2) AS srednia_cena
FROM 
  cab_rides_br
GROUP BY 
  typ_dnia;


-- ############################################################################
-- # Zadanie 5: Dzielnice z najczęstszym występowaniem podwyższonych stawek
-- ############################################################################
-- # Cel: Identyfikacja dzielnic, w których najczęściej występują przejazdy 
-- # z podwyższoną stawką.
-- #
-- # Wartość biznesowa: 
-- # - Identyfikacja obszarów o wysokim popycie
-- # - Lepsze zarządzanie flotą
-- # - Optymalizacja strategii cenowej w określonych lokalizacjach
-- ############################################################################

SELECT 
  -- Identyfikacja dzielnicy
  source,
  -- Zliczanie wystąpień dla każdej dzielnicy
  COUNT(*) AS count,
  -- Obliczenie średniego mnożnika podwyższonej stawki
  ROUND(AVG(surge_multiplier), 2) AS avg_surge
FROM cab_rides_br
-- Filtrowanie przejazdów z mnożnikiem podwyższonej ceny
WHERE surge_multiplier <> 1
GROUP BY source
-- Sortowanie według liczby przejazdów malejąco
ORDER BY count DESC;


-- ############################################################################
-- # Zadanie 6: Wpływ wilgotności na średnie ceny przejazdów
-- ############################################################################
-- # Cel: Zbadanie związku między poziomem wilgotności a średnimi cenami 
-- # przejazdów.
-- #
-- # Wartość biznesowa: 
-- # - Zrozumienie, jak warunki atmosferyczne wpływają na ceny
-- # - Wsparcie dla strategii dynamicznego ustalania cen
-- # - Lepsza predykcja zapotrzebowania
-- ############################################################################

SELECT
  -- Kategoryzacja poziomów wilgotności na przedziały co 0.05
  floor(humidity*20)/20 as floor_humidity,
  -- Obliczenie średniej ceny dla każdego przedziału wilgotności
  ROUND(AVG(price), 2) as avg_price_by_humidity,
  -- Obliczenie globalnej średniej ceny jako punktu odniesienia
  ROUND((SELECT AVG(price) FROM cab_rides_br), 2) AS global_avg_price
FROM
  cab_rides_br crb
-- Połączenie danych przejazdów z danymi pogodowymi
JOIN weather_br wb 
  ON crb.time_stamp = wb.time_stamp
  AND crb.source = wb.location
GROUP BY 1
ORDER BY 1;


-- ############################################################################
-- # Zadanie 7: Porównanie cen między Uberem a Lyftem przy podobnych dystansach
-- ############################################################################
-- # Cel: Porównanie cen między Uberem a Lyftem przy podobnych dystansach 
-- # (+/- 0,5 mili).
-- #
-- # Wartość biznesowa: 
-- # - Bezpośrednie porównanie konkurencyjności cenowej obu usług
-- # - Wsparcie dla analiz benchmarkingowych
-- # - Informacje wspierające decyzje o dostosowaniu cen
-- ############################################################################

-- Metoda 1: Z wykorzystaniem Common Table Expressions (CTE)
WITH
-- CTE dla średnich cen Uber według dystansu
avg_price_Uber AS (
  SELECT
    -- Kategoryzacja dystansów co 0.5 mili
    FLOOR(distance*2)/2 AS floor_distance,
    -- Średnia cena dla każdego przedziału dystansu
    ROUND(AVG(price), 2) AS avg_price_Uber
  FROM
    cab_rides_br
  WHERE cab_type = 'Uber'
  GROUP BY 1
  ORDER BY 1
),
-- CTE dla średnich cen Lyft według dystansu
avg_price_Lyft AS (
  SELECT
    -- Kategoryzacja dystansów co 0.5 mili
    FLOOR(distance*2)/2 AS floor_distance,
    -- Średnia cena dla każdego przedziału dystansu
    ROUND(AVG(price), 2) AS avg_price_Lyft
  FROM
    cab_rides_br
  WHERE cab_type = 'Lyft'
  GROUP BY 1
  ORDER BY 1
)
-- Połączenie wyników dla porównania cen obu usług
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

-- Metoda 2: Z wykorzystaniem subquery
SELECT 
  u.floor_distance,
  u.avg_price_Uber,
  l.avg_price_Lyft
FROM 
  (
    -- Subquery dla średnich cen Uber według dystansu
    SELECT
      -- Kategoryzacja dystansów co 0.5 mili
      FLOOR(distance*2)/2 AS floor_distance,
      -- Średnia cena dla każdego przedziału dystansu
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
    -- Subquery dla średnich cen Lyft według dystansu
    SELECT
      -- Kategoryzacja dystansów co 0.5 mili
      FLOOR(distance*2)/2 AS floor_distance,
      -- Średnia cena dla każdego przedziału dystansu
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


-- ############################################################################
-- # Zadanie 8: Analiza dni tygodnia z najczęstszymi podwyżkami cen
-- ############################################################################
-- # Cel: Identyfikacja dni tygodnia, w których najczęściej dochodzi do 
-- # podwyższenia cen.
-- #
-- # Wartość biznesowa: 
-- # - Identyfikacja dni z największym zapotrzebowaniem
-- # - Wsparcie planowania zasobów
-- # - Optymalizacja strategii cenowej
-- ############################################################################

-- Metoda 1: Z użyciem numerycznego oznaczenia dnia tygodnia
SELECT 
  -- Ekstrakcja numeru dnia tygodnia
  DAYOFWEEK(time_stamp) AS day_number,
  -- Zliczanie przejazdów z podwyższoną stawką
  count(*) as count
FROM cab_rides_br
-- Filtrowanie przejazdów z mnożnikiem podwyższonej ceny
WHERE surge_multiplier > 1
GROUP BY 1
-- Sortowanie według liczby przejazdów malejąco
ORDER BY 2 DESC;

-- Metoda 2: Z użyciem nazwy dnia tygodnia dla lepszej czytelności
SELECT 
  -- Ekstrakcja nazwy dnia tygodnia
  DAYNAME(time_stamp) AS day_name,
  -- Zliczanie przejazdów z podwyższoną stawką
  count(*) as count
FROM cab_rides_br
-- Filtrowanie przejazdów z mnożnikiem podwyższonej ceny
WHERE surge_multiplier > 1
GROUP BY 1
-- Sortowanie według liczby przejazdów malejąco
ORDER BY 2 DESC;


-- ############################################################################
-- # Zadanie 9: Identyfikacja najdroższych przejazdów z każdej dzielnicy
-- ############################################################################
-- # Cel: Znalezienie trzech najdroższych przejazdów z każdej dzielnicy.
-- #
-- # Wartość biznesowa: 
-- # - Informacje o skrajnych przypadkach cenowych
-- # - Identyfikacja potencjalnych anomalii
-- # - Wskazanie szczególnie rentownych tras
-- ############################################################################

SELECT 
  source,
  price,
  most_expensive_rides
FROM
(
  SELECT 
    source,
    price,
    -- Użycie funkcji okna do nadania rang przejazdów według ceny
    ROW_NUMBER() OVER (PARTITION BY source ORDER BY price DESC) AS most_expensive_rides
  FROM
    cab_rides_br
) AS ranked_rides
-- Filtrowanie trzech najwyżej ocenionych przejazdów z każdej dzielnicy
WHERE 
  most_expensive_rides <= 3;


-- ############################################################################
-- # Zadanie 10: Identyfikacja rekordowo długich przejazdów dla każdego typu usługi
-- ############################################################################
-- # Cel: Znalezienie rekordowo długich przejazdów dla każdego typu usługi.
-- #
-- # Wartość biznesowa: 
-- # - Identyfikacja ekstremów w długości przejazdów
-- # - Wskazanie specjalnych przypadków użycia
-- # - Identyfikacja niestandardowego zapotrzebowania klientów
-- ############################################################################

SELECT 
  name,
  distance,
  longest_rides
FROM
(
  SELECT 
    name,
    distance,
    -- Użycie funkcji okna do nadania rang przejazdów według dystansu
    ROW_NUMBER() OVER (PARTITION BY name ORDER BY distance DESC) AS longest_rides
  FROM
    cab_rides_br
) AS ranked_rides
-- Filtrowanie tylko najdłuższego przejazdu z każdego typu usługi
WHERE 
  longest_rides <= 1
-- Sortowanie według dystansu malejąco
ORDER BY 2 DESC;


-- ############################################################################
-- # Zadanie 11: Kompleksowa analiza przejazdów Uber według dni tygodnia
-- ############################################################################
-- # Cel: Kompleksowa analiza przejazdów Uber według dni tygodnia, uwzględniająca 
-- # godziny szczytowe.
-- #
-- # Wartość biznesowa: 
-- # - Kompleksowy widok wzorców korzystania z Ubera
-- # - Wsparcie decyzji dotyczących alokacji zasobów
-- # - Optymalizacja strategii cenowej
-- ############################################################################

WITH 
-- CTE do znalezienia godzin z największą liczbą przejazdów dla każdego dnia
peak_hours AS (
  SELECT
    -- Ekstrakcja nazwy dnia tygodnia
    DAYNAME(time_stamp) as day_name,
    -- Ekstrakcja godziny dnia
    HOUR(time_stamp) as hour_of_day,
    -- Zliczanie przejazdów w danej godzinie
    COUNT(*) as ride_count,
    -- Użycie funkcji okna do znalezienia godziny z największą liczbą przejazdów
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
  -- Formatowanie godziny szczytu
  MAKETIME(p.hour_of_day, 0, 0) as peak_hour_uber
FROM (
  -- Subquery do obliczenia podstawowych statystyk dla Ubera według dni tygodnia
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
-- Połączenie wyników z danymi o godzinach szczytowych
JOIN peak_hours p ON m.day_name = p.day_name AND p.rn = 1;


-- ############################################################################
-- # Zadanie 12: Kompleksowa analiza przejazdów Lyft według dni tygodnia
-- ############################################################################
-- # Cel: Kompleksowa analiza przejazdów Lyft według dni tygodnia, uwzględniająca 
-- # godziny szczytowe.
-- #
-- # Wartość biznesowa: 
-- # - Kompleksowy widok wzorców korzystania z Lyfta
-- # - Możliwość porównania z Uberem
-- # - Identyfikacja różnic w zachowaniach klientów
-- ############################################################################

WITH 
-- CTE do znalezienia godzin z największą liczbą przejazdów dla każdego dnia
peak_hours AS (
  SELECT
    -- Ekstrakcja nazwy dnia tygodnia
    DAYNAME(time_stamp) as day_name,
    -- Ekstrakcja godziny dnia
    HOUR(time_stamp) as hour_of_day,
    -- Zliczanie przejazdów w danej godzinie
    COUNT(*) as ride_count,
    -- Użycie funkcji okna do znalezienia godziny z największą liczbą przejazdów
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
  -- Formatowanie godziny szczytu
  MAKETIME(p.hour_of_day, 0, 0) as peak_hour_lyft
FROM (
  -- Subquery do obliczenia podstawowych statystyk dla Lyfta według dni tygodnia
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
-- Połączenie wyników z danymi o godzinach szczytowych
JOIN peak_hours p ON m.day_name = p.day_name AND p.rn = 1;


-- ############################################################################
-- # Zadanie 13: Analiza liczby przejazdów według godziny
-- ############################################################################
-- # Cel: Analiza dystrybucji liczby przejazdów w zależności od godziny dnia, 
-- # z podziałem na Uber i Lyft.
-- #
-- # Wartość biznesowa: 
-- # - Szczegółowa analiza rozkładu czasowego popytu
-- # - Identyfikacja godzin szczytu
-- # - Porównanie udziałów rynkowych obu usług w różnych porach dnia
-- ############################################################################

SELECT 
  -- Ekstrakcja godziny z timestampu
  HOUR(time_stamp) AS hour_number,
  -- Konwersja do formatu godzinowego dla lepszej czytelności
  MAKETIME(HOUR(time_stamp), 0, 0) AS hour_of_day,
  -- Segregacja liczby przejazdów według dostawcy
  SUM(CASE WHEN cab_type = 'Uber' THEN 1 ELSE 0 END) AS uber_count,
  SUM(CASE WHEN cab_type = 'Lyft' THEN 1 ELSE 0 END) AS lyft_count,
  -- Całkowita liczba przejazdów
  count(*) as total_count
FROM 
  cab_rides_br
GROUP BY 
  HOUR(time_stamp), 
  MAKETIME(HOUR(time_stamp), 0, 0)
ORDER BY 
  HOUR(time_stamp);


-- ############################################################################
-- # Zadanie 14: Analiza liczby przejazdów i godzin szczytu według dzielnic
-- ############################################################################
-- # Cel: Kompleksowa analiza liczby przejazdów i godzin szczytu według dzielnic.
-- #
-- # Wartość biznesowa: 
-- # - Szczegółowa analiza popytu według lokalizacji
-- # - Identyfikacja godzin szczytu dla każdej dzielnicy
-- # - Wsparcie decyzji dotyczących alokacji zasobów i strategie operacyjne
-- ############################################################################

WITH 
-- CTE do zliczania przejazdów według dzielnicy i godziny
ride_counts_per_hour AS (
  SELECT 
    source,
    HOUR(time_stamp) AS ride_hour,
    COUNT(*) AS rides_in_hour
  FROM cab_rides_br
  GROUP BY source, HOUR(time_stamp)
),
-- CTE do znalezienia maksymalnej liczby przejazdów dla każdej dzielnicy
max_rides AS (
  SELECT 
    source,
    MAX(rides_in_hour) AS max_rides
  FROM ride_counts_per_hour
  GROUP BY source
)
SELECT 
  c.source,
  -- Całkowita liczba przejazdów w dzielnicy
  COUNT(*) AS total_rides,
  -- Godzina z największą liczbą przejazdów
  MAKETIME(r.ride_hour, 0, 0) AS peak_hour,
  -- Liczba przejazdów w godzinie szczytu
  r.rides_in_hour AS rides_at_peak
FROM cab_rides_br c
-- Połączenie z danymi o liczbie przejazdów według godziny
JOIN ride_counts_per_hour r ON c.source = r.source
-- Połączenie z danymi o maksymalnej liczbie przejazdów
JOIN max_rides m ON r.source = m.source AND r.rides_in_hour = m.max_rides
GROUP BY c.source, r.ride_hour, r.rides_in_hour
-- Sortowanie według łącznej liczby przejazdów
ORDER BY total_rides DESC;
