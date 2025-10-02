--NashvilleHousingData hiya dataset d ventes des immobilier fi Nashville
--bech na3mloulha DATA CLEANING

----------------------------------------------------------------------------
--Quick check  lil  Data:
----------------------------------------------------------------------------

select * from Portfolio..NashvilleHousingData 

--nombre des lignes
select count(*) from Portfolio..NashvilleHousingData 

--Les colonnes
SELECT COLUMN_NAME , DATA_TYPE
FROM Portfolio.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'NashvilleHousingData';

----------------------------------------------------------------------------
--Colonne SaleDate:
----------------------------------------------------------------------------
select SaleDate from Portfolio..NashvilleHousingData
--Date & time mafama 7ata fayda mil time , donc nconvertiw data type vers date only

ALTER TABLE Portfolio..NashvilleHousingData
ALTER COLUMN SaleDate DATE; --DONE , Update mat3adatach (mana3rfch aleh) 

----------------------------------------------------------------------------
--PropertyAddress
----------------------------------------------------------------------------

Select * from Portfolio..NashvilleHousingData where PropertyAddress is NULL order by ParcelID
-- nla7dhou enou colonne PropertyAddress feha NULLS


SELECT *
FROM Portfolio..NashvilleHousingData
WHERE ParcelID IN (
    SELECT ParcelID
    FROM Portfolio..NashvilleHousingData
    GROUP BY ParcelID
    HAVING COUNT(*) > 1
)
order by ParcelID;
--nla7dhou enou the same ParceID 3andou the same PropertyAdress w different Unique ID : 
--exemple:
select ParcelID ,PropertyAddress,UniqueID from Portfolio..NashvilleHousingData where ParcelID = '025 12 0 029.00'

--donc najmou nestghalo il info hedhi bech na7iw NULLS eli fil colonne propertyAddress puisque fema relation bin ParceID w PropertyAdress 
select A.ParcelID,A.PropertyAddress , B.ParcelID , B.PropertyAddress
from Portfolio..NashvilleHousingData A
join Portfolio..NashvilleHousingData B
on A.ParcelID=B.ParcelID
Where a.PropertyAddress is null

--9rib nouslou lil table li 7achetna bih 
--Mais l9ina eno a droite PropertyAdress feha nulls also !
--bc each ParcelID has his own Unique ID 
--so lezmna nzido another condition
select A.ParcelID,A.PropertyAddress , B.ParcelID , B.PropertyAddress
from Portfolio..NashvilleHousingData A
join Portfolio..NashvilleHousingData B
on A.ParcelID=B.ParcelID 
and a.UniqueID <> b.UniqueID
Where a.PropertyAddress is null --finally ! 

--ma mazel ken bech na3mlo update lil PropertAdress
UPDATE A
Set PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress) -->if a.PropertyAddress is null , 3awedhneha  b the b.PropertyAddress value eli na7na t2akdna meno a travers  a.UniqueID <> b.UniqueID mahouch bch ykun null
from Portfolio..NashvilleHousingData A
join Portfolio..NashvilleHousingData B
on A.ParcelID=B.ParcelID 
and a.UniqueID <> b.UniqueID
Where a.PropertyAddress is null

Select * from Portfolio..NashvilleHousingData where PropertyAddress is NULL order by ParcelID
--empty ;) good
--Done!

------------------------------------------------------------------------------
SELECT PropertyAddress  FROM Portfolio..NashvilleHousingData 

--1808  FOX CHASE DR, GOODLETTSVILLE
--1808 FOX CHASE DR : Street + house number
--GOODLETTSVILE : hiya city 
--bch na9smou colonne PropertyAdrres L deux colonnes 
--delimiter bech ykun comma ','
--bech nesta3mlo fonction : SUBSTRING lil extraction + CHARINDEX : bch na3rfo il position mta3 il comma
--syntax : SUBSTRING(expression, start, length)


select 
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) as Street from Portfolio..NashvilleHousingData -- zidt -1 bch manhezech il comma 

select
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) as town from Portfolio..NashvilleHousingData

--nzido deux colonnes:
ALTER TABLE Portfolio..NashvilleHousingData
add PropertyStreet NVARCHAR(255)



ALTER TABLE Portfolio..NashvilleHousingData
add PropertyCity NVARCHAR(255)

--tawa na3lmo il UPDATE
Update Portfolio..NashvilleHousingData
SET PropertyStreet=  SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)  from Portfolio..NashvilleHousingData 

Update Portfolio..NashvilleHousingData
SET PropertyCity=  SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))   from Portfolio..NashvilleHousingData

select PropertyAddress, PropertyStreet,PropertyCity  from Portfolio..NashvilleHousingData --DONE ! 

 

-----------------------------------------------------------------------------------------------------------------------
--OwnerAddress
-----------------------------------------------------------------------------------------------------------------------
select OwnerAddress from Portfolio..NashvilleHousingData
--1808  FOX CHASE DR, GOODLETTSVILLE, TN
--Bech na3mlo nafs il 7aja m3a Colonne OwnerAddress ema b methode okhra li hiya PARSENAME  
--PARSENAME('object_name', part_number)
select 
PARSENAME(REPLACE(OwnerAddress,',','.'),3), --REPLACE(OwnerAddress,',','.') = 1808  FOX CHASE DR. GOODLETTSVILLE. TN because delimiter li tekhdem bih PARSENAME huwa il point mouch il comma
PARSENAME(REPLACE(OwnerAddress,',','.'),2), -- 3 hiya il postion 
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
from Portfolio..NashvilleHousingData

--nzido les colonnes 
ALTER TABLE Portfolio..NashvilleHousingData
add OwnerStreet NVARCHAR(255)

ALTER TABLE Portfolio..NashvilleHousingData
add OwnerCity NVARCHAR(255)

ALTER TABLE Portfolio..NashvilleHousingData
add OwnerState NVARCHAR(255)

Update Portfolio..NashvilleHousingData
SET OwnerStreet=PARSENAME(REPLACE(OwnerAddress,',','.'),3)

Update Portfolio..NashvilleHousingData
SET OwnerCity=PARSENAME(REPLACE(OwnerAddress,',','.'),2)

Update Portfolio..NashvilleHousingData
SET  OwnerState=PARSENAME(REPLACE(OwnerAddress,',','.'),1)

select OwnerAddress,OwnerCity, OwnerState,OwnerStreet   from Portfolio..NashvilleHousingData


-----------------------------------------------------------------------------------------------------------------------
--Column: SoldAsVacant
-----------------------------------------------------------------------------------------------------------------------
Select Distinct(soldAsVacant) from Portfolio..NashvilleHousingData 
--najmo 0 wil 1 n3awdhouhom b no w yes

ALTER TABLE Portfolio..NashvilleHousingData
ALTER COLUMN SoldAsVacant VARCHAR(3); --Data type badalto bc Column SoldAsVacant kenit type Bit

UPDATE Portfolio..NashvilleHousingData
SET SoldAsVacant = CASE WHEN SoldAsVacant = '0' THEN 'No'
                        WHEN SoldAsVacant = '1' THEN 'Yes'
                   END;

Select Distinct(soldAsVacant) from Portfolio..NashvilleHousingData 


-----------------------------------------------------------------------------------------------------------------------
--REMOVE DUPLICATES
-----------------------------------------------------------------------------------------------------------------------
-- bch na3rfo anahom duplicated rows 
With RowCTE as (
select * , row_number() over (partition by ParcelID,propertyAddress,SalePrice,SaleDate,LegalReference order by UniqueID) as rn from Portfolio..NashvilleHousingData)
select * from RowCTE
where rn > 1 
order by PropertyAddress-- where rn > 1 traja3lik il duplicated rows

With RowCTE as (
select * , row_number() over (partition by ParcelID,propertyAddress,SalePrice,SaleDate,LegalReference order by UniqueID) as rn from Portfolio..NashvilleHousingData)
select * from RowCTE
where rn > 1 
order by PropertyAddress-- where rn > 1 traja3lik il duplicated rows -- where rn = 1 traja3lik il original rows

--explication:  ki na3mlo row_number partition by ..... lezm kol row ykun feha rank 1 c.a.d unique row 
--si feha rank 2 or more (>1) that means eno row adhika deja mawjuda 9bal w khdhet 1 
--ki n7ebo nchoufou il original rows , rn=1 , par contre kinhebou nchouf il duplicated rows , rn>1
--execute: select * , row_number() over (partition by ParcelID,propertyAddress,SalePrice,SaleDate,LegalReference order by UniqueID) as rn from Portfolio..NashvilleHousingData

--DELETE DUPLICATES 
With RowCTE as (
select * , row_number() over (partition by ParcelID,propertyAddress,SalePrice,SaleDate,LegalReference order by UniqueID) as rn from Portfolio..NashvilleHousingData)
DELETE  from RowCTE
where rn > 1 

--CHECK
With RowCTE as (
select * , row_number() over (partition by ParcelID,propertyAddress,SalePrice,SaleDate,LegalReference order by UniqueID) as rn from Portfolio..NashvilleHousingData)
select * from RowCTE
where rn > 1 
order by PropertyAddress --EMPTY ! Done ;)

--------------------------------------------------------------------------------------------------------------------------------------------------
--Delete unused Columns
---------------------------------------------------------------------------------------------------------------------------------------------
Alter table Portfolio..nashvilleHousingData
drop column owneraddress,taxdistrict,propertyAddress,SaleDate


----------------------------
--FINAL TABLE
----------------------------
select *   from portfolio..nashvilleHousingData

 
