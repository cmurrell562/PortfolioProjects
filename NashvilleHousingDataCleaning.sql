/*
Nashville Housing Data Cleaning

Skills used: 
- Joins, CTE's, Windows Functions, SUBSTRING_INDEX, Case Statements, Alter Table, Drop Column

Summary
- Standarized date format from string to %y/%m/%d
- Populated null property addresses and then broke down addresses into address, city, and state columns to support further analysis using SUBSTRING_INDEX
- Cleaned columns that used different verbiage to represent the same information, using case statements
- Removed duplicates using Window Functions and CTE
- Deleted unused columns to condense the table and make it easier to look at 

*/



SELECT *
FROM NashvilleHousing nh ;

SELECT SaleDate_converted
FROM NashvilleHousing nh ;

-------------------------------------------------
-- Standarize Date Format %y/%m/%d from string
-- Populate SaleDate_converted by using SaleDate in a date type format
ALTER TABLE  NashvilleHousing 
Add SaleDate_converted Date

UPDATE NashvilleHousing nh 
SET SaleDate_converted = STR_TO_DATE(SaleDate, '%M %e, %Y')

----------------------------------------------------
-- Populate Property Address Data


-- property that is being sold should not have null address
-- the mapping from parcel id to property address is constant, meaning if multiple records have the same parcel id
	--they would have the same propery address. We can use this mapping to populate NULL property addresses when a parcel id exists
	-- (self join on parcel id but its not the same row (do not join on same uniqueid)
	-- for every property record,find other records with the same ParcelID but is not the same row
-- NULLIF(a.propertyaddress, '') → turns empty strings into NULL
-- COALESCE(..., b.propertyaddress) → if the first argument is now NULL, use b.propertyaddress
--  Can verify NashvilleHousing was updated and all empty property addresses were populated by
	-- running a query with WHERE nh.PropertyAddress = '' to see if anything was returned
UPDATE NashvilleHousing nh
JOIN NashvilleHousing nh2 
  ON nh.ParcelID = nh2.ParcelID 
 AND nh.UniqueID != nh2.UniqueID
SET nh.PropertyAddress = COALESCE(NULLIF(nh.PropertyAddress, ''), nh2.PropertyAddress)
WHERE nh.PropertyAddress = '';


----------------------------------------------------------------------
-- Breaking out Address into Individual Columns (Address, City, State)

-- Add a VarChar columm
ALTER TABLE  NashvilleHousing 
Add PropertySplitAddress Varchar(255)

-- Update the newly added column with values
-- Return everything in PropertyAddress before the first comma
UPDATE NashvilleHousing nh 
SET PropertySplitAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1)

ALTER TABLE  NashvilleHousing 
Add PropertySplitCity Varchar(255)

-- Return everything in PropertyAddress after the first comma from the end
UPDATE NashvilleHousing nh 
SET PropertySplitCity = SUBSTRING_INDEX(PropertyAddress, ',', -1)

ALTER TABLE  NashvilleHousing 
Add OwnerSplitAddress Varchar(255)

UPDATE NashvilleHousing nh 
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1)

ALTER TABLE  NashvilleHousing 
Add OwnerSplitCity Varchar(255)

-- Return everything in PropertyAddress after the second comma from the end, then return everything before the fist comma
	-- '123 Main St, Nashville, TN' --> Nashville
UPDATE NashvilleHousing nh 
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',',1)

ALTER TABLE  NashvilleHousing 
Add OwnerSplitState Varchar(255)

UPDATE NashvilleHousing nh 
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1)


---------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" field

Update NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 Else SoldAsVacant
		 END
		 
-------------------------------------------------------

-- Remove Duplicates
DELETE nh
FROM NashvilleHousing nh
JOIN (
  SELECT UniqueID
  FROM (
    SELECT UniqueID,
           ROW_NUMBER() OVER (
             PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
             ORDER BY UniqueID
           ) AS row_num
    FROM NashvilleHousing
  ) t
  WHERE row_num > 1
) dupes
ON nh.UniqueID = dupes.UniqueID;

-------------------------------------
-- Delete Unused Columns

Select *
FROM NashvilleHousing nh ;

ALTER TABLE NashvilleHousing 
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress

ALTER TABLE NashvilleHousing 
DROP COLUMN SaleDate

