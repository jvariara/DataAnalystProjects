/*
	Covid 19 Data Exploration 

	Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

Select *
From PortfolioProject..CovidDeaths
where continent is not null
Order by 3,4

-- Cleaning data so that if total_cases is 0 we can set to null so that we can use it to get death percentage
Update PortfolioProject..CovidDeaths
Set total_cases = NULL
where total_cases = 0

-- Select Data that we are going to be using
Select continent, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 1, 2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your continent
Select continent, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
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
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Order by 1, 2


-- Looking at Total Population vs Vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition By dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Using a CTE so that we can use the RollingPeopleVaccinated Column to perform a calculation
With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition By dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
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
From PortfolioProject..CovidDeaths dea
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