--Project 1 Apple Inc

--Create Continent and Country Tables
CREATE TABLE Continent (ContinentId INT PRIMARY KEY, [Name] NVARCHAR(50))

CREATE TABLE Country (CountryId INT PRIMARY KEY, CountryName NVARCHAR(50), ContinentId INT )

--Add foreign key constraint to country table
ALTER TABLE Country
ADD CONSTRAINT FK_Continent
FOREIGN KEY (ContinentId) REFERENCES Continent(ContinentId)

--Add Tax column to country table
ALTER TABLE Country
ADD Tax DECIMAL(3,2);

select * from Continent
select * from Country



--Code to generate random taxes in countries
declare @counter int=0
declare @rowcount int =196
declare @countryID int
declare @tax DECIMAL(3,2)
while @counter<=196
begin
	set @counter = @counter+1
	set @tax = (SELECT (FLOOR(RAND()*(25-1+1))+1)/100)
	;with A (rownumber,countryCode,countryName)AS (
select ROW_NUMBER() over (order by c.Countryid),c.CountryId,c.CountryName from Country c 
) SELECT @countryID = (SELECT countryCode FROM A where rownumber=@counter)
  
	
	update Country SET Tax = @tax
	where CountryId = @countryID
end
--------------------------------------------------------------------------------------------------

--DROP TABLE ProductCategory
CREATE TABLE ProductCategory 
(
CategoryId INT PRIMARY KEY IDENTITY(1,1), 
CategoryName NVARCHAR(50)
)
--DROP TABLE SubCategory
CREATE TABLE SubCategory
(
	SubcategoryId INT PRIMARY KEY IDENTITY (1,1), 
	SubcategoryName NVARCHAR(50), CategoryID INT
)

SELECT * FROM ProductCategory
SELECT * FROM SubCategory

CREATE TABLE Product
(
	ProductId INT PRIMARY KEY,
	ProductName NVARCHAR(50),
	SubcategoryId INT FOREIGN KEY REFERENCES Subcategory(SubcategoryId),
	ProductionCost DECIMAL(7,2)
)

SELECT * FROM Product


-----------------------------------------------------------------------------------------------------------------------

--Create Production House Table
CREATE TABLE ProductionHouse
(
	Id INT PRIMARY KEY,
	[Name] NVARCHAR(50),
	LocationId INT FOREIGN KEY REFERENCES Country(CountryId)
)

alter table productionHouse ADD CONSTRAINT PK_ID pRIMARY KEY (Id)

select * from ProductionHouse


--------------------------------------------------------------------------------

--------------------------------------------------------------------

--Create table to assemble products
CREATE  TABLE AssembledProduct
(
AssemblyId INT PRIMARY KEY IDENTITY(1,1),
ProdcutId INT FOREIGN KEY REFERENCES Product(ProductId),
LocationId INT FOREIGN KEY REFERENCES ProductionHouse(Id),
[ProductionDate] DateTime,
ProductionCost Decimal(7,2),
SerialNumber NVARCHAR(25) UNIQUE
)




--test table
Insert into AssembledProduct (ProdcutId,LocationId,ProductionDate,ProductionCost,SerialNumber)
VALUES
(1212,1331, CURRENT_TIMESTAMP, 610, 'ME7690900'
)
select * from AssembledProduct
TRUNCATE table AssembledProduct

select * from AssembledProduct
------------------------------------------------------------

--TABLE TO IDENTIFY TYPE OF STORAGE WHETHER IT IS COMPANY FACILITY OR RETAIL STORE
CREATE TABLE [Location]
(
	LocationId INT PRIMARY KEY,
	LocationType NVARCHAR (30)
)
INSERT INTO [Location] VALUES
	(1,	'Production Facility'),
	(2,	'Company Warehouse'),
	(3,	'Distributor Warehouse'),
	(4,	'Channel Partner'),
	(5,	'Retail Store')

SELECT * FROM [Location]

update Location set LocationType='Subdistributor'
where LocationId =3
------------------------------------------------------------------------------
--DROP TABLE Warehouse
CREATE TABLE Warehouse 
(
	WarehouseId INT PRIMARY KEY IDENTITY(1,1),
	WarehouseName NVARCHAR(50),
	WarehouseType INT FOREIGN KEY REFERENCES [Location](LocationId), --TYPE of warehouse
	GeoLocation INT FOREIGN KEY REFERENCES Country(CountryId) --in which country warehouse is located
)

ALTER TABLE Warehouse 
ADD SupplierId INT

------------------------------------------------
CREATE TABLE StockInventory
(
	ProductId INT FOREIGN KEY REFERENCES Product(ProductId),
	WarehouseId INT FOREIGN KEY REFERENCES Warehouse(WarehouseId),
	Quantity INT,
	CONSTRAINT PK_Stock PRIMARY KEY (ProductId,WarehouseId)
 )

 SELECT * FROM StockInventory

 CREATE TABLE TransactionType
 (
 [Type] CHAR(1) UNIQUE,
 [Description] NVARCHAR(30)
 )

 INSERT INTO TransactionType VALUES
 ('A','Assembly of Product'),
 ('T','Transfer between Warehouses'),
 ('S','Sale'),
 ('R','Return'),
 ('D','Destruction of Product')

 SELECT * FROM TransactionType

 DROP TABLE [Transaction]
 CREATE TABLE [Transaction]
 (
	TransactionId INT PRIMARY KEY IDENTITY(1,1),
	ProductId INT FOREIGN KEY REFERENCES Product(ProductId),
	ReferenceNo INT, --References any type of transaction(sale,assembly,transfer,etc)
	TransactionType CHAR(1) FOREIGN KEY REFERENCES TransactionType([Type]),
	Quantity INT DEFAULT 0,
	TransactionDate DateTime,
	TransactionCost Decimal(9,2)
)

SELECT * FROM [Transaction]


CREATE TABLE ProductionLog
(
 SerialNumber NVARCHAR(25) UNIQUE,
 ProductId INT FOREIGN KEY REFERENCES Product(ProductId),
 WarehouseId INT FOREIGN KEY REFERENCES Warehouse(WarehouseId),
 ActualCost DECIMAL(7,2),
 IsSold BIT DEFAULT 0 
)

SELECT RIGHT(CONVERT(NVARCHAR,DATEPART(YY,GETDATE())),2)+
       RIGHT('0'+CONVERT(nvarchar,DATEPART(MM,GETDATE())),2)+
	   CONVERT(NVARCHAR,DATEPART(DD,GETDATE()))+
       CONVERT(NVARCHAR,DATEPART(HH,GETDATE()))+
	   CONVERT(NVARCHAR,DATEPART(MINUTE,GETDATE()))+
	   CONVERT(nvarchar,DATEPART(DD,GETDATE()))

---------------------------------------------------------
--Create Function to generate serial number

----------------------------------------------------
GO  
ALTER FUNCTION dbo.ufnGenerateSerialNumber(@ProductID int,@FacilityId int)  
RETURNS NVARCHAR(25)  
AS   
-- Generates serial number for product 
BEGIN  
     DECLARE @serialNumber NVARCHAR(25)
    DECLARE @facilityCode NVARCHAR(2);
    SET @facilityCode = (SELECT UPPER(LEFT(Name,2)) FROM ProductionHouse WHERE Id=@FacilityId)
 SET @serialNumber=( SELECT  @facilityCode+ 
		CONVERT(NVARCHAR,131)+
	   CONVERT(NVARCHAR,1217)+
	   RIGHT(CONVERT(NVARCHAR,DATEPART(YY,GETDATE())),2)+
       RIGHT('0'+CONVERT(nvarchar,DATEPART(MM,GETDATE())),2)+
	   CONVERT(NVARCHAR,DATEPART(DD,GETDATE()))+
       CONVERT(NVARCHAR,DATEPART(HH,GETDATE()))+
	   CONVERT(NVARCHAR,DATEPART(MINUTE,GETDATE()))+
	   CONVERT(nvarchar,DATEPART(SS,GETDATE())))
     
    RETURN @serialNumber;  
END; 

SELECT len(dbo.ufnGenerateSerialNumber(1217,3511))
select CONVERT(nvarchar,DATEPART(MCS,GETDATE()))

------------------------------------------------------------------------------------------------------------------------


EXEC Produce 701,10,2081

SELECT* FROM StockInventory
select * from AssembledProduct
select * from ProductionLog
select count(*) from ProductionLog where WarehouseId=5031

select * from [Transaction]
--UPDATE [Transaction] SET ReferenceNo=5 WHERE TransactionId=5
select * from Product

SELECT SUM(ProductionCost)FROM AssembledProduct WHERE WorkId=5

CREATE TABLE Customer
(
  CustomerId INT PRIMARY KEY IDENTITY(1,1), 
  FirstName NVARCHAR(20),
  LastName NVARCHAR(20),
  PhoneNumber NVARCHAR(12),
  PasportNo NVARCHAR UNIQUE
)


select * from Customer

SELECT PL.SerialNumber,P.ProductId,P.ProductName,pl.ActualCost,
PH.Name  AS [Produced At],PL.WarehouseId as CurrentLocationId,
w.WarehouseName AS CurrentLocation,l.LocationType as LocationType, 
CASE 
    WHEN IsSold=0 THEN 'NO'
	ELSE 'YES'
	END AS IsSold
FROM ProductionLog  PL
JOIN AssembledProduct AP ON PL.SerialNumber=AP.SerialNumber
JOIN ProductionHouse PH ON PH.Id=AP.LocationId
JOIN Warehouse W ON W.WarehouseId= PL.WarehouseId
JOIN [Location] L ON L.LocationId=W.WarehouseType
JOIN Product P ON P.ProductId=PL.ProductId


SELECT * FROM ProductDetailedView

CREATE TABLE TransferLog
(
	TransferId INT PRIMARY KEY IDENTITY(1,1),
	SenderId INT,
	ReceiverId INT,
	[Date] Datetime,
	SerialNumber NVARCHAR(35),
	TransferOrder INT
)
select * from transferlog

CREATE SEQUENCE transferOrder  
    START WITH 1 
    INCREMENT BY 1 ;  


select WarehouseId,ProductId, COUNT(ProductId) AS [Available Quantity]from ProductionLog
GROUP BY ProductId,WarehouseId

