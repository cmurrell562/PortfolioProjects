-- select *
-- from CovidVaccinations 
-- limit 5;
-- 
-- select *
-- from CovidDeaths
-- limit 5;

-- Select Data that we are going to be using
Select Location, date_parsed, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2;

-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in your country
Select Location, date_parsed, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE Location LIKE '%states%'
ORDER BY 1,2;

-- Looking at the Total Cases vs the Population
-- Shows estimate of what percentage of population got Covid (noting a person could have gotten it multiple times)
Select Location, date_parsed, Population, total_cases, (total_cases/Population)*100 as PercentPopulationInfected
WHERE Location LIKE '%states%'
ORDER BY 1,2;

-- Looking at Countries with highest infection rate compared to population
Select Location, Population, MAX(total_cases) HighestInfectionCount, (MAX(total_cases)/Population)*100 as PercentPopulationInfected
FROM CovidDeaths
-- WHERE Location LIKE '%states%'
GROUP by Location,Population
ORDER BY PercentPopulationInfected DESC;

-- Showing the countries with highest death count per population
-- cast from varchar, not ordered properly
Select Location, MAX(cast(total_deaths as UNSIGNED)) TotalDeathCount, Continent
FROM CovidDeaths
WHERE continent != ''
GROUP by Location, Continent
ORDER BY TotalDeathCount  DESC;



-- Breakdown by continent


-- Total death count for each continent
-- cast from varchar, not ordered properly
Select Continent, MAX(cast(total_deaths as UNSIGNED)) TotalDeathCount
FROM CovidDeaths
WHERE continent != ''
GROUP by Continent
ORDER BY TotalDeathCount DESC;


-- Global Numbers

-- DeathPercentage across world per day
Select date_parsed, SUM(new_cases) TotalCases, SUM(new_deaths) TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 DeathPercentage
FROM CovidDeaths
WHERE continent != ''
GROUP BY date_parsed
ORDER BY 1,2; 

-- Looking at total population vs vaccinations 
-- % of population vaccinated
-- Use CTE
WITH PopvsVac (Continent, Location, date_parsed, Populations, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT cd.continent, cd.location, cd.date_parsed, cd.population, cv.new_vaccinations
, SUM(cv.new_vaccinations) OVER (Partition by cd.location ORDER BY cd.location, cd.date_parsed) RollingPeopleVaccinated
FROM CovidDeaths cd 
JOIN CovidVaccinations cv 
	ON cd.location = cv.location AND cd.date_parsed = cv.date_parsed
WHERE cd.continent != ''
-- ORDER BY 2,3
)
SELECT  *, (RollingPeopleVaccinated/Populations)*100
FROM PopvsVac

-- USE TEMP TABLE

DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated (
  Continent                 VARCHAR(255),
  Location                  VARCHAR(255),
  `Date`                    DATETIME,
  Population                DECIMAL(12,0),
  New_vaccinations          DECIMAL(12,0),
  RollingPeopleVaccinated   DECIMAL(18,0)
);

INSERT INTO PercentPopulationVaccinated
  (Continent, Location, `Date`, Population, New_vaccinations, RollingPeopleVaccinated)
  -- mysql wont insert into ' ', convert '' to int
SELECT
  cd.continent,
  cd.location,
  cd.date_parsed,
  CAST(NULLIF(REPLACE(cd.population, ',', ''), '') AS UNSIGNED) AS Population,
  CAST(NULLIF(REPLACE(cv.new_vaccinations, ',', ''), '') AS UNSIGNED) AS New_vaccinations,
  SUM(
    COALESCE(CAST(NULLIF(REPLACE(cv.new_vaccinations, ',', ''), '') AS UNSIGNED), 0)
  ) OVER (PARTITION BY cd.location ORDER BY cd.date_parsed) AS RollingPeopleVaccinated
FROM CovidDeaths cd
JOIN CovidVaccinations cv
  ON cd.location = cv.location
 AND cd.date_parsed = cv.date_parsed
 WHERE cd.continent != '';

SELECT
  *,
  100.0 * RollingPeopleVaccinated / NULLIF(Population, 0) AS pct_vaccinated
FROM PercentPopulationVaccinated;


-- Creating view to store data for later visualizations

Create View PercentPopulationVaccinated as
SELECT cd.continent, cd.location, cd.date_parsed, cd.population, cv.new_vaccinations
, SUM(cv.new_vaccinations) OVER (Partition by cd.location ORDER BY cd.location, cd.date_parsed) RollingPeopleVaccinated
FROM CovidDeaths cd 
JOIN CovidVaccinations cv 
	ON cd.location = cv.location AND cd.date_parsed = cv.date_parsed
WHERE cd.continent != ';

SELECT *
FROM PercentPopulationVaccinated;



