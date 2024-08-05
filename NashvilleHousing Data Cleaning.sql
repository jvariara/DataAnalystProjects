/*
	
Cleaning Data With SQL Queries

*/

Select *
From PortfolioProject..NashvilleHousing

----------------------------------------------------------------------------------

-- Standardize Date Format
-- Removing the Time from the SaleDate

Select SaleDate, CONVERT(Date, SaleDate)
From PortfolioProject..NashvilleHousing

-- Have to first change the column type from datetime to just date

ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate Date;

Update NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

----------------------------------------------------------------------------------

-- Populate Property Address Data

-- If the property address is null, there are two rows with the same parcel id, which means those PropertyAddress will be the same
-- so we can just update the row with a null value the same as the one that isn't null

Select *
From PortfolioProject..NashvilleHousing
--Where PropertyAddress is null
order by ParcelID

-- Do a self join to check if the ParcelIDs are the same, then the PropertyAddress's should be the same
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ] -- Makes sure we aren't checking the same row
Where a.PropertyAddress is null

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

----------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

-- We can use the comma as a delimiter between Address and City

Select PropertyAddress
From PortfolioProject..NashvilleHousing

Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as Address,
LTRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))) as City
From PortfolioProject..NashvilleHousing

-- Add new columns and add the date in

ALTER TABLE NashvilleHousing
Add PropertyStreetAddress nvarchar(255)

Update NashvilleHousing
SET PropertyStreetAddress = TRIM(SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1))

ALTER TABLE NashvilleHousing
Add PropertyCityAddress nvarchar(255)

Update NashvilleHousing
SET PropertyCityAddress = TRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)))


Select PropertyStreetAddress, PropertyCityAddress
From PortfolioProject..NashvilleHousing

-- Now we work on the OwnerAddress

Select OwnerAddress
From PortfolioProject..NashvilleHousing

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
From PortfolioProject..NashvilleHousing

-- Add new columns and add the date in

ALTER TABLE NashvilleHousing
Add OwnerStreetAddress nvarchar(255)

Update NashvilleHousing
SET OwnerStreetAddress = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3))

ALTER TABLE NashvilleHousing
Add OwnerCityAddress nvarchar(255)

Update NashvilleHousing
SET OwnerCityAddress = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2))

ALTER TABLE NashvilleHousing
Add OwnerStateAddress nvarchar(255)

Update NashvilleHousing
SET OwnerStateAddress = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1))

Select OwnerStreetAddress, OwnerCityAddress, OwnerStateAddress
From PortfolioProject..NashvilleHousing

----------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" Column

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From PortfolioProject..NashvilleHousing
Group By SoldAsVacant
Order By 2

Select SoldAsVacant,
CASE	
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END
From PortfolioProject..NashvilleHousing

Update NashvilleHousing
SET SoldAsVacant = CASE	
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END

----------------------------------------------------------------------------------

-- Remove Duplicates
-- Duplicates are when ParcelID, PropertyAddress, SalePrice, SaleDate, and LegalReference are all the same

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
From PortfolioProject..NashvilleHousing
-- order by ParcelID
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
From PortfolioProject..NashvilleHousing
-- order by ParcelID
)
DELETE
From RowNumCTE
Where row_num > 1

----------------------------------------------------------------------------------

-- Delete Unused Columns  

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

----------------------------------------------------------------------------------