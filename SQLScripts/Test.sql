
--functions
SELECT dbo.ufnAdd8percent(100)
SELECT dbo.ufnGenerateSerialNumber(1216,2081)
SELECT dbo.ufnCalculateProductionCost(1216,2281)

--Stored Procedures
EXEC Produce 601,100,3511  --Stored Procedure to produce a product

EXEC transferProduct 861,2,6618  --Transfer Product to Warehouse

EXEC SellProduct 3,13770,1210,1--Sell product to customer

exec SellProduct

EXEC returnItem 8 --Return Item

SELECT* FROM StockInventory
select * from AssembledProduct
select * from ProductionLog where issold=0
select count(*) from ProductionLog where IsSold=0
SELECT SUM(Quantity) FROM StockInventory
SELECT* FROM [Transaction]
select * from Customer
SELECT * FROM SaleOrder
SELECT * FROM SaleOrderDetails
select * from Warehouse where WarehouseType=5
select * from Product

select * from ReturnedItem
--Views-
SELECT * FROM SupplyChainView
SELECT * FROM ProductDetailedView Where  LocationType LIKE 'R%'

