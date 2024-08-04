Select *
From PortfolioProject..CovidDeaths
where continent is not null
Order by 3,4

--Select *
--From PortfolioProject..CovidVaccinations
--Order by 3,4

-- Select Data that we are going to be using
Select continent, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 1, 2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your continent
Select continent, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where total_cases > 0 and continent is not null
Order by 1, 2

-- Looking at Total Cases vs Population
-- Shows what percemntage of population got covid
Select continent, date, total_cases, population, (total_cases/population)*100 as PopulationInfectedPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 1, 2

-- Looking at continent with Highest Infection Rate compared to Population
Select continent, population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as PopulationInfectedPercentage
From PortfolioProject..CovidDeaths
where continent is not null
group by continent, population
Order by PopulationInfectedPercentage desc

-- Showing continents with the Highest Death Count per Population
Select continent, MAX(total_deaths) as TotalDeathCount
From PortfolioProject..CovidDeaths
where continent is not null
group by continent
Order by TotalDeathCount desc

-- GLOBAL NUMBERS
Select date, SUM(new_cases), SUM(new_deaths), SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where total_cases > 0 and continent is not null
group by date
Order by 1, 2


DROP TABLE IF EXISTS #temp_CovidDeaths
CREATE TABLE PortfolioProject..#temp_CovidDeaths (
[iso_code] nvarchar(255),
[continent] nvarchar(255),
[location] nvarchar(255),
[date] datetime,
[population] float,
[total_cases] float,
[new_cases] float,
[new_cases_smoothed] float,
[total_deaths] float,
[new_deaths] float,
[new_deaths_smoothed] float,
[total_cases_per_million] float,
[new_cases_per_million] float,
[new_cases_smoothed_per_million] float,
[total_deaths_per_million] float,
[new_deaths_per_million] float,
[new_deaths_smoothed_per_million] float,
[reproduction_rate] nvarchar(255),
[icu_patients] nvarchar(255),
[icu_patients_per_million] nvarchar(255),
[hosp_patients] nvarchar(255),
[hosp_patients_per_million] nvarchar(255),
[weekly_icu_admissions] nvarchar(255),
[weekly_icu_admissions_per_million] nvarchar(255),
[weekly_hosp_admissions] nvarchar(255),
[weekly_hosp_admissions_per_million] nvarchar(255)
)

Insert into #temp_CovidDeaths
Select * from CovidDeaths

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From #temp_CovidDeaths
Where continent is not null
--group by date
Order by 1, 2


-- Looking at Total Population vs Vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition By dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From #temp_CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Using a CTE so that we can use the RollingPeopleVaccinated Column for another column
With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition By dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From #temp_CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
Select *, (RollingPeopleVaccinated/population)*100
from PopvsVac

-- Using a temp table for same example as above
Drop Table if exists #temp_PercentPopulationVaccinated
Create Table #temp_PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #temp_PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition By dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From #temp_CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select *, (RollingPeopleVaccinated/population)*100
from #temp_PercentPopulationVaccinated


-- Creating View to store data for later visualizations
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition By dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.total_cases > 0 and dea.new_cases > 0 and dea.continent is not null

Select *
From PercentPopulationVaccinated