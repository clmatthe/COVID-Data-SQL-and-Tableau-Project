SELECT * 
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT null
ORDER BY 3,4


--SELECT * 
--FROM PortfolioProject..CovidVaccinations$
--ORDER BY 3,4

--Selecting data to start with, get an overall look at the table
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT null
ORDER BY 1,2


--Investigating total cases vs. total deaths
--Shows likelihood of death if you were to contract COVID in your country 

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProject..CovidDeaths$
WHERE location LIKE '%states%' AND continent IS NOT null 
ORDER BY 1,2

--Investigating total cases vs. population
--Shows percentage of population infected with COVID for each country 

SELECT location, date, total_cases, Population, (total_cases/population) * 100 AS case_percentage
FROM PortfolioProject..CovidDeaths$
WHERE location LIKE '%states%' AND continent IS NOT null 
ORDER BY 1,2

--Displaying hospital patients vs. total cases
--Shows percentage of people that were hospitalized out of overall COVID cases 

SELECT location, date, total_cases, hosp_patients, (hosp_patients/total_cases) * 100 AS hosp_percentage 
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT null 
ORDER BY 1,2

--Investigating countries with highest infection rate per capita 
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX(total_cases/population)*100 AS percent_pop_infected 
FROM PortfolioProject..CovidDeaths$
GROUP BY location, population
WHERE continent IS NOT null
ORDER BY percent_pop_infected DESC

--Displaying countries with highest death count per capita 
SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count, MAX(total_deaths/population)*100 AS percent_pop_death
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT null
GROUP BY location
ORDER BY total_death_count DESC

--Breaking things down by continent: 

--Displaying continents with the highest death count per capita
SELECT continent, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT null
GROUP BY continent
ORDER BY total_death_count DESC

--Global numbers

SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS death_percentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT null
ORDER BY 1,2

--Displaying total population vs. vaccinations 
--Percentage of population that received at least one COVID vaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location,
dea.Date) as rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths$ dea 
JOIN PortfolioProject..CovidVaccinations$ vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
order by 2,3 

--Using CTE to perform calculation on PARTITION BY in previous query
WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated) AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location,
dea.Date) as rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths$ dea 
JOIN PortfolioProject..CovidVaccinations$ vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
)
SELECT *, (rolling_people_vaccinated/population)*100
FROM pop_vs_vac

--Using temp table to perform calculation on PARTITION BY in previous query 
DROP TABLE IF EXISTS #percent_pop_vaccinated 
CREATE TABLE #percent_pop_vaccinated
(continent nvarchar(255),
location nvarchar(255), 
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)
INSERT INTO #percent_pop_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location,
dea.Date) as rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths$ dea 
JOIN PortfolioProject..CovidVaccinations$ vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null

SELECT *, (rolling_people_vaccinated/population)*100
FROM #percent_pop_vaccinated

--Creating view to store data for later visualizations 
USE PortfolioProject
GO
CREATE VIEW percentpopvaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location,
dea.Date) as rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths$ dea 
JOIN PortfolioProject..CovidVaccinations$ vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
