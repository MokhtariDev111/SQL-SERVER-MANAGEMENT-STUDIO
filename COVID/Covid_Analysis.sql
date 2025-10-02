-------------------------------------------------------------------------------------------------------------------------------
--Ken l9it mochkla f data type f colonne
-------------------------------------------------------------------------------------------------------------------------------
ALTER TABLE esm_database_mte3ik..CovidDeaths
ALTER COLUMN new_cases FLOAT;
--OR USE : 
--CAST(column_name) AS .....

 
-------------------------------------------------------------------------------------------------------------------------------
--nektachfo il Data  : CovidDeaths
-------------------------------------------------------------------------------------------------------------------------------
 


SELECT 
Location, date, new_cases, total_cases,   total_deaths, population
FROM Portfolio..CovidDeaths
ORDER BY Location, date;
--------------------
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM Portfolio.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidDeaths';
--------------------

select 
COUNT(*) AS NumberOfColumns
FROM Portfolio.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidDeaths'; --nombre colonne
--------------------
select 
count( *) as 'number of rows'
from Portfolio..CovidDeaths --nombre des lignes
--------------------
select 
Cast(min(date) as date) as 'first date' , Cast(max(date) as date) as 'last_date' 
from Portfolio..CovidDeaths -- date
--------------------
select 
year(min (date)) as Starting , year(max(date)) as ending 
from portfolio..CovidDeaths -- date
-------------------------------------------------------------------------------------------------------------------------------
--Countries
-------------------------------------------------------------------------------------------------------------------------------
select
distinct(location) 
from Portfolio..CovidDeaths 
order by location

-------------------------------------------------------------------------------------------------------------------------------
--nombre total lil infected w death f kol dawla.
-------------------------------------------------------------------------------------------------------------------------------
select
location , sum (new_cases) as total_cases , sum (new_deaths) as total_deaths --sum(new_cases) = max(total_cases)
from Portfolio..CovidDeaths
where continent is not null 
group by location 
order by  location

-------
--TOP 5
-------
 SELECT TOP 5
    Location, 
    Population, 
    MAX(total_deaths) as HighestDeathCount 
FROM Portfolio..CovidDeaths
where continent is not NULL
GROUP BY Location, Population
ORDER BY HighestDeathCount DESC  ;

-------------------------------------------------------------------------------------------------------------------------------
--nombre total lil infected w death f kol continent.
-------------------------------------------------------------------------------------------------------------------------------
select
location , sum (new_cases) as total_cases , sum (new_deaths) as total_deaths 
from Portfolio..CovidDeaths
where continent is null 
group by location
order by  total_deaths desc


-------------------------------------------------------------------------------------------------------------------------------
--Pourcentage cumule mte3 el 3bed eli 9a3da tomrodh chaque jour min kol population 
-------------------------------------------------------------------------------------------------------------------------------
    SELECT 
        location,
		date, 
		Population,
        total_cases, 
        CONCAT(
               ROUND(total_cases * 100.0 / population,5),'%') 
         AS InfectionPercentage
    FROM Portfolio..CovidDeaths
	where continent is not null
    ORDER BY location, date;

-------------------------------------------------------------------------------------------------------------------------------
--Pourcentage cumule mte3 la3bed eli 9a3da tmout chaque jour min kol population   
-------------------------------------------------------------------------------------------------------------------------------
    SELECT 
        location, 
		Population,
        total_deaths,
        CONCAT(
               ROUND(total_deaths * 100.0 / population,4),'%') 
         AS DeathPercentage
    FROM Portfolio..CovidDeaths
    Where continent is not null
    ORDER BY location 
---------------------------------------------------------------------------------------------------------
--Pourcentage mte3 la3bed eli mordhit w min ba3d  metit f kol population  
---------------------------------------------------------------------------------------------------------
select 
location, Population , ROUND( sum (new_deaths)*100.0/sum (new_cases),3) as DeathPercentage
from Portfolio..CovidDeaths 
where continent is not null
group by location , population
order by  location 


-------------------------------------------------------------------------------------------------------------------------------
--Pourcentage  infection eli 9aydeteha kol Location 
-------------------------------------------------------------------------------------------------------------------------------
 SELECT 
    Location, 
    Population, 
    MAX(total_cases) as HighestInfectionCount, 
   ROUND( MAX(total_cases/population),5) * 100 as PercentPopulationInfected
FROM Portfolio..CovidDeaths
where continent is not NULL 
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;



-------------------------------------------------------------------------------------------------------------------------------
--Pourcentage maximal lil deaths eli 9aydeteha kol Location fi population mta3ha
-------------------------------------------------------------------------------------------------------------------------------

 SELECT 
    Location, 
    Population, 
    MAX(total_deaths) as HighestDeathCount, 
    MAX((total_deaths/population)) * 100 as PercentPopulationDeath
FROM Portfolio..CovidDeaths
where continent is not NULL
GROUP BY Location, Population
ORDER BY  PercentPopulationDeath DESC  ;

-------
--TOP 5
-------

 SELECT TOP 5
    Location, 
    Population, 
    MAX(total_deaths) as HighestDeathCount, 
    MAX((total_deaths/population)) * 100 as PercentPopulationDeath
FROM Portfolio..CovidDeaths
where continent is not NULL
GROUP BY Location, Population
ORDER BY  PercentPopulationDeath DESC  ;

 

-------------------------------------------------------------------------------------------------------------------------------
--9adech min infection sarit f kol nhar fi el 3alem
-------------------------------------------------------------------------------------------------------------------------------
SELECT 
 date , SUM(new_cases) as total_cases 
 from Portfolio..CovidDeaths
 where continent is not null  and total_cases is not null
 group by date
 order by date 
-------------------------------------------------------------------------------------------------------------------------------
--9adech min death sarit f kol nhar fi el 3alem
-------------------------------------------------------------------------------------------------------------------------------------
SELECT 
CAST(date as Date) as Dateonly , SUM(new_deaths) as total_deaths
 from Portfolio..CovidDeaths
 where continent is not null and total_deaths is not null
 group by CAST(date as Date)
 order by Dateonly

-------------------------------------------------------------------------------------------------------------------------------
 --global casses , death , pourcentage
-------------------------------------------------------------------------------------------------------------------------------
 select 
 SUM(new_cases) as total_cases ,
 SUM(new_deaths)as total_deaths,
  ROUND(SUM(new_deaths) /  SUM(new_cases) * 100,4) as DeathPercentage 
  from Portfolio..CovidDeaths
  where continent is not null 
  order by 1,2


 
-------------------------------------------------------------------------------------------------------------------------------
--Bech na3mlo join pour les deux tables bech nzido net3am9o akther fil analyse
-------------------------------------------------------------------------------------------------------------------------------
    SELECT *
    FROM Portfolio..CovidVaccinations
---------------------------------------- 

select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
from Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccinations vac
ON dea.location =vac.location
and dea.date=vac.date
where dea.continent is not null
order by 1,2,3



-------------------------------------------------------------------------------------------------------------------------------
--Nzido colonne nsamiwha total_vaccinations n7oto feha new_vaccinations cumule
-------------------------------------------------------------------------------------------------------------------------------
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (partition by dea.Location Order by dea.location,dea.Date)  as 'total_vaccinations'
from Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccinations vac
ON dea.location =vac.location
and dea.date=vac.date
where dea.continent is not null
order by 2

------------------------------------
-- Population vs Vaccinations
-- Bech nesta3mlou isnull bech na3mlo division mte3na btari9a safe akther
------------------------------------
WITH PopVac AS 
(
    SELECT 
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        ISNULL(vac.new_vaccinations, 0) AS new_vaccinations,
        SUM(ISNULL(vac.new_vaccinations, 0)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS total_vaccinations
    FROM Portfolio..CovidDeaths dea
    JOIN Portfolio..CovidVaccinations vac
        ON dea.location = vac.location
       AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *,
       ROUND(total_vaccinations * 100.0 / population, 4) AS PercantageOfVaccinated
FROM PopVac
ORDER BY location, date;

 

----------------------------------
--Pourcentage mte3 kol location wil vaccin
---------------------------------
SELECT 
    dea.location,
	dea.population,
    ROUND(MAX(CAST(vac.people_vaccinated AS FLOAT)) * 100.0 / dea.population, 2) AS PercentPeopleVaccinated,
    ROUND(MAX(CAST(vac.people_fully_vaccinated AS FLOAT)) * 100.0 / dea.population, 2) AS PercentFullyVaccinated
FROM Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccinations vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.location, dea.population
ORDER BY PercentPeopleVaccinated DESC;
--Gibraltar → 111.29%: still over 100% because they also vaccinated non-residents


------------------------------------------------------------
--query bdet titwal , donc na3mlo creation mta3 view 
-----------------------------------------------------------
 
CREATE VIEW CovidVacc as 
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (partition by dea.Location Order by dea.location,dea.Date)  as 'total_vaccinations'
from Portfolio..CovidDeaths dea
JOIN Portfolio..CovidVaccinations vac
ON dea.location =vac.location
and dea.date=vac.date
where dea.continent is not null
 
 select * from CovidVacc
