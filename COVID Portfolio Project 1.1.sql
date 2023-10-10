-- Produces the full CovidDeaths table

SELECT *
FROM "public"."CovidDeaths"
ORDER BY 3,4;

-- Produces the full CovidVaccinations table

SELECT *
FROM "public"."CovidVaccinations"
ORDER BY 3,4;

-- Displays a few of the designated columns selected from the CovidDeaths table

SELECT "location", date, total_cases, new_cases, total_deaths, population
FROM "public"."CovidDeaths"
ORDER BY "location", date;

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT "location", date, total_cases, total_deaths, COALESCE(total_deaths/NULLIF(total_cases,0))*100 AS DeathPercentage
FROM "public"."CovidDeaths"
WHERE "location" ILIKE '%States%'
ORDER BY "location", date;

-- Looking at the Total Cases vs Population
-- Shows what percentage of population got Covid

SELECT "location", date, total_cases, population, COALESCE(total_cases/NULLIF(population,0))*100 AS DeathPercentage
FROM "public"."CovidDeaths"
WHERE "location" ILIKE '%States%'
ORDER BY "location", date;

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT "location", population, Max (total_cases) AS HighestInfectionCount, Max(COALESCE(total_cases/NULLIF(population,0)))*100 AS PercentagePopulationInfected
FROM "public"."CovidDeaths"
GROUP BY "location",population
ORDER BY PercentagePopulationInfected DESC;

-- Showing Countries with the Highest Death Count per Population

SELECT "location", Max (total_deaths) AS TotalDeathCount
FROM "public"."CovidDeaths"
WHERE continent <> 'Other'
GROUP BY "location"
ORDER BY TotalDeathCount DESC;

-- Showing the Death breakdown by Continent using Location

SELECT "location", Max(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM "public"."CovidDeaths"
WHERE continent = 'Other'
GROUP BY "location"
ORDER BY TotalDeathCount DESC;

-- Let's break things down by Continent using the Continent column

SELECT continent, Max(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM "public"."CovidDeaths"
WHERE continent <> 'Other'
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Showing continents with the highest death count per population

SELECT continent, Max(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM "public"."CovidDeaths"
WHERE continent <> 'Other'
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Global Numbers

SELECT 
    date, 
    sum(CAST(new_cases AS INT)) AS new_cases, 
    sum(CAST(new_deaths AS INT)) AS new_deaths,
    sum(NULLIF(new_deaths,0))/sum(NULLIF(new_cases,0))*100 AS DeathPercentage
FROM "public"."CovidDeaths"
WHERE continent <> 'Other'
GROUP BY date
ORDER BY 1,2;

--Global Numbers in Total

SELECT 
    sum(new_cases) AS total_cases,  
    sum(CAST(new_deaths AS INT)) AS total_deaths,
    sum(NULLIF(new_deaths,0))/sum(NULLIF(new_cases,0))*100 AS DeathPercentage
FROM "public"."CovidDeaths"
WHERE continent <> 'Other'
--GROUP by date
ORDER BY 1,2;

--- Looking at Total Population vs. Vaccinations

SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       sum(vac.new_vaccinations)
            OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) 
                AS RollingPeopleVaccinated

FROM "CovidDeaths" AS dea
JOIN "CovidVaccinations" AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> 'Other'
ORDER BY 2,3;

--- Looking at Total Population vs. Vaccniations using CTE


WITH PopvsVac (Continent, "location", Date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       sum(vac.new_vaccinations)
            OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) 
                AS RollingPeopleVaccinated

FROM "CovidDeaths" AS dea
JOIN "CovidVaccinations" AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> 'Other'
ORDER BY 2,3
)
SELECT *, (rollingpeoplevaccinated/population)*100 AS rollingvaccpercentage
FROM PopvsVac;


---Temp Table

DROP TABLE IF EXISTS PercentagePopulationVaccinated;
CREATE TABLE PercentagePopulationVaccinated
(
Continent VARCHAR (255),
LOCATION VARCHAR (255),
Date TIMESTAMP,
Population NUMERIC,
New_vaccinations NUMERIC,
RollingPeoplevaccinated NUMERIC
);

INSERT INTO PercentagePopulationVaccinated
SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       sum(vac.new_vaccinations)
            OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) 
                AS RollingPeopleVaccinated

FROM "CovidDeaths" AS dea
JOIN "CovidVaccinations" AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> 'Other';

SELECT *, (RollingPeoplevaccinated/Population)*100 AS Rollingvaccpercentage
FROM PercentagePopulationVaccinated;


--- Creating View to store data for Visualization via Tableau. This will visualize the Total Population for several countries against the total vaccinations consumed within that specific country.
CREATE VIEW PercentageOfPopulationVaccinated AS
SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       sum(vac.new_vaccinations)
            OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) 
                AS RollingPeopleVaccinated

FROM "CovidDeaths" AS dea
JOIN "CovidVaccinations" AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> 'Other'
ORDER BY 2,3;


--- Creating View to store data for Visualization via Tableau. This will breakdown the continents with the highest death count per population

CREATE VIEW DeathCountPerPopulation AS
SELECT continent, Max(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM "public"."CovidDeaths"
WHERE continent <> 'Other'
GROUP BY continent
ORDER BY TotalDeathCount DESC;
