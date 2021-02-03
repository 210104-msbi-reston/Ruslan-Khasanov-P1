----------------------------------------------------
--Some code to create stores
/*DECLARE @WarehouseCode INT
DECLARE @Counter INT =1;
DECLARE @CountryName NVARCHAR(50)
DECLARE  @countryCode INT
WHILE @Counter <=1560
BEGIN
		;WITH A (RowNum,warehouseId,warehouseName,countryCode,country)
		AS
		(
		 SELECT ROW_NUMBER() OVER (Order By GeoLocation),WarehouseId,WarehouseName,C.CountryId,C.CountryName FROM Warehouse
		 JOIN Country C ON C.CountryId=Warehouse.GeoLocation 
		 WHERE WarehouseType=4
		) SELECT @WarehouseCode = (SELECT warehouseId FROM A WHERE RowNum=@Counter)

		;WITH A (RowNum,warehouseId,warehouseName,countryCode,country)
		AS
		(
		 SELECT ROW_NUMBER() OVER (Order By GeoLocation),WarehouseId,WarehouseName,C.CountryId,C.CountryName FROM Warehouse
		 JOIN Country C ON C.CountryId=Warehouse.GeoLocation 
		 WHERE WarehouseType=4
		)SELECT @CountryName =(SELECT SUBSTRING(warehouseName,1,LEN(warehousename)-16) FROM A where warehouseId=@WarehouseCode)

		SET @countryCode = (SELECT GeoLocation FROM Warehouse WHERE WarehouseId=@WarehouseCode)

		DECLARE @innerCounter INT=1;

		WHILE @innerCounter <=4
		BEGIN
				INSERT INTO WAREHOUSE(WarehouseName,WarehouseType,GeoLocation,SupplierId)
				VALUES(@CountryName+' Store '+TRY_CAST(@innerCounter AS nvarchar),5,@countryCode,@WarehouseCode)
				
				SET @innerCounter=@innerCounter+1
          END
	SET @Counter=@Counter+1
END*/
---------------------------------------------------------------------------------------------------------------------

--Stored Procedure to manufacture a product
/*select * from AssembledProduct
GO
ALTER PROC Produce(@productId INT,@quantity INT,@factoryId INT)
AS
BEGIN
	
	DECLARE @cost DECIMAL(7,2)= (SELECT dbo.ufnCalculateProductionCost(@productId,@factoryId))
	DECLARE @serialNumber NVARCHAR(25)
	DECLARE @counter INT =0
	DECLARE @quantityInStock INT
	DECLARE @workId INT
	SET @workId =next value for workid
	WHILE @counter<@quantity
	BEGIN
			SET @serialNumber =(SELECT dbo.ufnGenerateSerialNumber(@productId,@factoryId))+convert(nvarchar,@counter)
			INSERT INTO AssembledProduct
			(ProdcutId,LocationId,ProductionDate,ProductionCost,SerialNumber,WorkId)
			VALUES
			(@productId,@factoryId,GETDATE(),@cost,@serialNumber,@workId)

			INSERT INTO ProductionLog
			(SerialNumber,ProductId,WarehouseId,ActualCost)
			VALUES
			(@serialNumber,@productId,@factoryId,@cost)

			SET @quantityInStock= (SELECT Quantity FROM StockInventory WHERE ProductId=@productId AND WarehouseId=@factoryId)

			IF @quantityInStock IS NULL
			
			    INSERT INTO StockInventory VALUES(@productId,@factoryId,1)
			ELSE 
				UPDATE StockInventory SET Quantity=@quantityInStock+1
				WHERE ProductId=@productId AND WarehouseId=@factoryId
			
			SET @counter=@counter+1
      END

	  DECLARE @totalCost DECIMAL (9,2)
	  SET @totalCost =(SELECT SUM(ProductionCost)FROM AssembledProduct WHERE WorkId=@workId)
	  INSERT INTO [Transaction] (ProductId,ReferenceNo,TransactionType,Quantity,TransactionDate,TransactionCost)
	  VALUES
	  (@productId,@workId,'A',@quantity,GETDATE(),@totalCost)

END*/
------------------

--CREATE FUNCTION TO CALCULATE PRODUCTION COST PER LOCATION

/*GO  
ALTER FUNCTION dbo.ufnCalculateProductionCost(@ProductID int,@FacilityId int)  
RETURNS DECIMAL(9,2)  
AS   
-- Returns production of the production at the production house.  
BEGIN  
    DECLARE @cost decimal(7,2); 
	DECLARE @tax decimal(7,2);
	DECLARE @countryId int;
	SELECT @countryId = (SELECT LocationId FROM ProductionHouse WHERE Id= @FacilityId)
	SELECT @tax = (SELECT Tax FROM Country WHERE CountryId=@countryId)
	SELECT @cost =((SELECT ProductionCost FROM Product WHERE ProductId= @ProductID)*@tax)+(SELECT ProductionCost FROM Product WHERE ProductId= @ProductID)
   
     IF (@cost IS NULL)   
        SET @cost = 0;  
    RETURN @cost;  
END; */
--Test function
SELECT dbo.ufnCalculateProductionCost(1218,2071)
------------------------------------------------------------------------
--CREATE FUNCTION TO ADD 8 % PER TRANSFER
/*GO
CREATE FUNCTION dbo.ufnAdd8percent(@cost DECIMAL(9,2)) 
RETURNS DECIMAL(9,2)
AS
BEGIN
   RETURN @COST*0.08 +@COST
END
*/
--SELECT dbo.ufnAdd8percent(308)

--Stored Procedure to create purchase order
go
ALTER PROC transferProduct(@productId INT,@quantity INT,@warehouse INT)
AS
BEGIN
	
	DECLARE @supplier INT = (SELECT SupplierId FROM Warehouse WHERE WarehouseId=@warehouse)
	DECLARE @quantityInStock INT = (SELECT Quantity FROM StockInventory where ProductId=@productId AND WarehouseId=@supplier)
	IF @quantityInStock<@quantity   --Check if there is sufficient anount of product in stock
	BEGIN
			PRINT 'Insufficient Stock'
			RETURN
	END

	IF @quantityInStock IS NULL
	BEGIN
		PRINT 'You entered Invalid Parameters'
		RETURN
	END

	UPDATE StockInventory SET Quantity = @quantityInStock-@quantity WHERE ProductId=@productId AND WarehouseId=@supplier--REDUCE SUPPLIER STOCK
    DECLARE @serialNumber NVARCHAR(35)
     DECLARE @cost DECIMAL(7,2)
	 DECLARE @totalCost DECIMAL (9,2)=0
	 
     DECLARE @counter INT =1
	 DECLARE @transferId INT
	SET @transferId =next value for transferOrder 
	WHILE @counter<=@quantity
	BEGIN
			--SELECT SERIAL NUMBER
			SET @serialNumber= (SELECT TOP 1 SERIALNUMBER FROM ProductionLog WHERE ProductId=@productId AND WarehouseId=@supplier)

			SET @cost= (SELECT ActualCost FROM ProductionLog WHERE SerialNumber=@serialNumber) --SELECT COST
			SELECT @cost = dbo.ufnAdd8percent(@cost) --AD TRANSFER FEE TO COST

			UPDATE ProductionLog SET WarehouseId =@warehouse, ActualCost=@cost where SerialNumber=@serialNumber --update product location and cost

			INSERT INTO TransferLog(SenderId,ReceiverId,[date],serialNumber, transferOrder) 
			VALUES(@supplier,@warehouse,GETDATE(),@serialNumber,@transferId)

			SET @totalCost = @totalCost+@cost
			SET @counter=@counter+1
      END

	 
	  
	  INSERT INTO [Transaction] (ProductId,ReferenceNo,TransactionType,Quantity,TransactionDate,TransactionCost)
	  VALUES
	  (@productId,@transferId,'T',@quantity,GETDATE(),@totalCost)

	  --Update RECEIVER WAREHOUSE stock
	SET @quantityInStock=(SELECT Quantity FROM StockInventory where ProductId=@productId AND WarehouseId=@warehouse)--CHECK uantity in receiving warehouse
	IF @quantityInStock IS NULL
	BEGIN 
	   INSERT INTO StockInventory(ProductId,WarehouseId,Quantity) VALUES(@productId,@warehouse,@quantity) --INCREASE RECEIVING STOCK
	END
	ELSE
	BEGIN
		UPDATE StockInventory SET Quantity=@quantity WHERE ProductId=@productId AND WarehouseId=@warehouse
	END

END



SELECT * FROM ProductDetailedView WHERE lLocationType LIKE 'R%' 

EXEC transferProduct 1216,10,6291

SELECT * FROM ProductionLog WHERE ProductId=1212 AND WarehouseId=7171

EXEC Produce 1212,1000,2071

UPDATE StockInventory SET Quantity=200 WHERE WarehouseId =1441

SELECT SUM(Quantity) FROM StockInventory

select ProductId,WarehouseId, COUNT(ProductId) AS [Available Quantity]from ProductionLog
GROUP BY ProductId,WarehouseId ORDER BY ProductId

SELECT * FROM StockInventory

SELECT Quantity FROM StockInventory where ProductId=1546 AND WarehouseId=15616

EXEC Produce 1210,20000,3511

EXEC transferProduct 1210,10,13772


select * from Customer
insert into Customer(FirstName,LastName,PhoneNumber,PasportNo)
VALUES('Pedro','Rodriguez','+3481376984','SP3789876')

CREATE TABLE SaleOrder
(
SaleOrderId INT PRIMARY KEY,
CustomerId INT FOREIGN KEY REFERENCES Customer(CustomerId),
TotalCost DECIMAL(9,2),
[Date] Datetime
)


CREATE TABLE SaleOrderDetails
(

 SaleOrderId INT FOREIGN KEY REFERENCES SaleOrder(SaleOrderId),
 ProductId INT FOREIGN KEY REFERENCES Product(ProductId),
 SerialNumber NVARCHAR(35) REFERENCES ProductionLog(SerialNumber),
 SalePrice DECIMAL (7,2)
)

CREATE SEQUENCE saleOrderNo 
    START WITH 1 
    INCREMENT BY 1 ;  


GO
alter PROC SellProduct(@customer INT=0, @store INT=13770,@productId INT=1210,@quantity INT=1)
AS
BEGIN
	IF @customer =0
	BEGIN
		  SET @customer=(SELECT floor(RAND()*(10-1)+1))
	END

	DECLARE @serialNumber NVARCHAR(35) =(SELECT TOP 1 SerialNumber FROM ProductionLog WHERE WarehouseId=@store AND IsSold=0)
	DECLARE @saleNo INT = NEXT VALUE FOR saleOrderNo
	INSERT INTO SaleOrder(SaleOrderId,CustomerId,[Date])
	VALUES(@saleNo,@customer,GETDATE())
	DECLARE @SalePrice DECIMAL(7,2)= (SELECT ActualCost FROM ProductionLog WHERE SerialNumber=@serialNumber)
	SET @SalePrice =(SELECT dbo.ufnAdd8percent(@SalePrice))

	INSERT INTO SaleOrderDetails VALUES
	(@saleNo,@productId,@serialNumber,@SalePrice)

	UPDATE ProductionLog SET IsSold=1 WHERE SerialNumber=@serialNumber
	UPDATE StockInventory set Quantity =Quantity-1 where ProductId=@productId AND WarehouseId=@store
	
	UPDATE SaleOrder SET TotalCost = @SalePrice WHERE SaleOrderId =@saleNo
	
	INSERT INTO [Transaction](ProductId,ReferenceNo,TransactionType,Quantity,TransactionDate,TransactionCost)
	VALUES(@productId,@saleNo,'S',@quantity,GETDATE(),@SalePrice)

END

EXEC SellProduct 
-------------------------------------
SELECT * FROM StockInventory where WarehouseId=12298
SELECT * FROM [Transaction]
SELECT * FROM ProductionLog where IsSold=1
SELECT * FROM AssembledProduct
SELECT * FROM TRANSFERLOG
SELECT * FROM ProductDetailedView WHERE LocationType LIKE 'R%'
select * from saleorder
select * from saleorderdetails

truncate table saleorder

SELECT floor(RAND()*(13000-9000+1)+8000)

select sum(quantity) from StockInventory


CREATE TABLE ReturnedItem
(
 ReturnId INT Primary Key IDENTITY(1,1),
 ReturnReason NVARCHAR(35),
 SerialNumber NVARCHAR(35),
 LocationId INT FOREIGN KEY REFERENCES Warehouse(WarehouseId),
)
-------------------------------------
GO
ALTER PROC returnItem(@saleNo INT,@reason NVARCHAR(30)='Factory Deffect',@location INT=0)
AS
BEGIN
	IF @location=0
	BEGIN
		 SET @location=(SELECT floor(RAND()*(13000-9000+1)+8000))
	END
	DECLARE @serialNumber NVARCHAR(35) = (SELECT SerialNumber FROM saleorderdetails WHERE saleOrderId= @saleNo)
	DECLARE @cost DECIMAL(7,2) = -(SELECT SalePrice FROM saleorderdetails WHERE saleOrderId= @saleNo)
	DECLARE @productId INT = (SELECT ProductId FROM saleorderdetails WHERE saleOrderId= @saleNo)
	INSERT INTO ReturnedItem VALUES
	(@reason,@serialNumber,@location)

	INSERT INTO [Transaction](ProductId,ReferenceNo,TransactionType,Quantity,TransactionDate,TransactionCost)
	VALUES(@productId,@saleNo,'R',1,GETDATE(),@cost)

END 

EXEC returnItem 5
SELECT * FROM [Transaction]
SELECT * FROM RETURNEDITEM