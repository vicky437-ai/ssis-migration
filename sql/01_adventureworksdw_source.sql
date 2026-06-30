/* =====================================================================
   AdventureWorksDW — source schema for the SSIS → Snowflake migration POC
   ---------------------------------------------------------------------
   Dialect: Microsoft SQL Server T-SQL (this is the SOURCE the migration
   agent assesses; it is authored in T-SQL on purpose, not Snowflake SQL).
   Schemas:
     dbo  — the AdventureWorksDW dimensional model (targets of the loads)
     stg  — staging tables the SSIS packages read FROM
   Column names are REAL AdventureWorksDW columns.
   ===================================================================== */

-------------------------------------------------------------------------
-- Schemas
-------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'stg')
    EXEC('CREATE SCHEMA stg');
GO

-------------------------------------------------------------------------
-- dbo dimensional / fact targets
-------------------------------------------------------------------------
CREATE TABLE dbo.DimProductCategory (
    ProductCategoryKey          INT             NOT NULL PRIMARY KEY,
    ProductCategoryAlternateKey INT             NULL,
    EnglishProductCategoryName  NVARCHAR(50)    NOT NULL
);
GO

CREATE TABLE dbo.DimProductSubcategory (
    ProductSubcategoryKey           INT             NOT NULL PRIMARY KEY,
    ProductSubcategoryAlternateKey  INT             NULL,
    EnglishProductSubcategoryName   NVARCHAR(50)    NOT NULL,
    ProductCategoryKey              INT             NULL
        REFERENCES dbo.DimProductCategory (ProductCategoryKey)
);
GO

CREATE TABLE dbo.DimProduct (
    ProductKey              INT             NOT NULL PRIMARY KEY,
    ProductAlternateKey     NVARCHAR(25)    NULL,
    EnglishProductName      NVARCHAR(50)    NOT NULL,
    ProductSubcategoryKey   INT             NULL
        REFERENCES dbo.DimProductSubcategory (ProductSubcategoryKey),
    Color                   NVARCHAR(15)    NULL,
    Size                    NVARCHAR(50)    NULL,
    StandardCost            MONEY           NULL,
    ListPrice               MONEY           NULL,
    ModelName               NVARCHAR(50)    NULL,
    Status                  NVARCHAR(7)     NULL
);
GO

CREATE TABLE dbo.DimGeography (
    GeographyKey            INT             NOT NULL PRIMARY KEY,
    City                    NVARCHAR(30)    NULL,
    StateProvinceName       NVARCHAR(50)    NULL,
    EnglishCountryRegionName NVARCHAR(50)   NULL,
    PostalCode              NVARCHAR(15)    NULL
);
GO

CREATE TABLE dbo.DimCustomer (
    CustomerKey             INT             NOT NULL PRIMARY KEY,
    GeographyKey            INT             NULL
        REFERENCES dbo.DimGeography (GeographyKey),
    CustomerAlternateKey    NVARCHAR(15)    NULL,
    FirstName               NVARCHAR(50)    NULL,
    LastName                NVARCHAR(50)    NULL,
    FullName                NVARCHAR(101)   NULL,
    BirthDate               DATE            NULL,
    MaritalStatus           NCHAR(1)        NULL,
    Gender                  NCHAR(1)        NULL,
    EmailAddress            NVARCHAR(50)    NULL,
    YearlyIncome            MONEY           NULL,
    EnglishEducation        NVARCHAR(40)    NULL
);
GO

CREATE TABLE dbo.FactInternetSales (
    ProductKey              INT             NOT NULL
        REFERENCES dbo.DimProduct (ProductKey),
    OrderDateKey            INT             NOT NULL,
    CustomerKey             INT             NOT NULL
        REFERENCES dbo.DimCustomer (CustomerKey),
    SalesTerritoryKey       INT             NULL,
    SalesOrderNumber        NVARCHAR(20)    NOT NULL,
    SalesOrderLineNumber    TINYINT         NOT NULL,
    OrderQuantity           SMALLINT        NULL,
    UnitPrice               MONEY           NULL,
    ProductStandardCost     MONEY           NULL,
    SalesAmount             MONEY           NULL,
    TaxAmt                  MONEY           NULL,
    OrderDate               DATETIME        NULL,
    CONSTRAINT PK_FactInternetSales
        PRIMARY KEY (SalesOrderNumber, SalesOrderLineNumber)
);
GO

-------------------------------------------------------------------------
-- stg staging sources (what the SSIS packages read FROM)
-------------------------------------------------------------------------
CREATE TABLE stg.Product (
    ProductAlternateKey     NVARCHAR(25)    NULL,
    EnglishProductName      NVARCHAR(50)    NOT NULL,
    ProductSubcategoryKey   INT             NULL,
    Color                   NVARCHAR(15)    NULL,
    Size                    NVARCHAR(50)    NULL,
    StandardCost            MONEY           NULL,
    ListPrice               MONEY           NULL,
    ModelName               NVARCHAR(50)    NULL,
    Status                  NVARCHAR(7)     NULL
);
GO

CREATE TABLE stg.Customer (
    CustomerAlternateKey    NVARCHAR(15)    NULL,
    GeographyKey            INT             NULL,
    FirstName               NVARCHAR(50)    NULL,
    LastName                NVARCHAR(50)    NULL,
    BirthDate               DATE            NULL,
    MaritalStatus           NVARCHAR(2)     NULL,
    Gender                  NVARCHAR(10)    NULL,
    EmailAddress            NVARCHAR(50)    NULL,
    YearlyIncome            MONEY           NULL,
    -- intentionally non-Unicode (VARCHAR) to drive a Data Conversion transform
    EnglishEducation        VARCHAR(40)     NULL
);
GO

CREATE TABLE stg.SalesOnline (
    ProductAlternateKey     NVARCHAR(25)    NULL,
    CustomerAlternateKey    NVARCHAR(15)    NULL,
    SalesTerritoryKey       INT             NULL,
    SalesOrderNumber        NVARCHAR(20)    NOT NULL,
    SalesOrderLineNumber    TINYINT         NOT NULL,
    OrderQuantity           SMALLINT        NULL,
    UnitPrice               MONEY           NULL,
    ProductStandardCost     MONEY           NULL,
    SalesAmount             MONEY           NULL,
    TaxAmt                  MONEY           NULL,
    OrderDate               DATETIME        NULL
);
GO

CREATE TABLE stg.SalesReseller (
    ProductAlternateKey     NVARCHAR(25)    NULL,
    CustomerAlternateKey    NVARCHAR(15)    NULL,
    SalesTerritoryKey       INT             NULL,
    SalesOrderNumber        NVARCHAR(20)    NOT NULL,
    SalesOrderLineNumber    TINYINT         NOT NULL,
    OrderQuantity           SMALLINT        NULL,
    UnitPrice               MONEY           NULL,
    ProductStandardCost     MONEY           NULL,
    SalesAmount             MONEY           NULL,
    TaxAmt                  MONEY           NULL,
    OrderDate               DATETIME        NULL
);
GO

CREATE TABLE stg.CurrencyRate (
    AverageRate             FLOAT           NULL,
    CurrencyKey             INT             NULL,
    CurrencyDateKey         INT             NULL,
    EndOfDayRate            FLOAT           NULL
);
GO

-------------------------------------------------------------------------
-- Reference data (lookup targets)
-------------------------------------------------------------------------
INSERT INTO dbo.DimProductCategory (ProductCategoryKey, ProductCategoryAlternateKey, EnglishProductCategoryName) VALUES
 (1,1,'Bikes'),(2,2,'Components'),(3,3,'Clothing'),(4,4,'Accessories');
GO

INSERT INTO dbo.DimProductSubcategory (ProductSubcategoryKey, ProductSubcategoryAlternateKey, EnglishProductSubcategoryName, ProductCategoryKey) VALUES
 (1,1,'Mountain Bikes',1),(2,2,'Road Bikes',1),(3,3,'Touring Bikes',1),
 (14,14,'Helmets',4),(31,31,'Jerseys',3),(37,37,'Tires and Tubes',4);
GO

-------------------------------------------------------------------------
-- stg.Product (~16 rows) — real-looking AdventureWorks products
-------------------------------------------------------------------------
INSERT INTO stg.Product (ProductAlternateKey, EnglishProductName, ProductSubcategoryKey, Color, Size, StandardCost, ListPrice, ModelName, Status) VALUES
 ('BK-M68B-38','Mountain-200 Black, 38',1,'Black','38',1251.98,2294.99,'Mountain-200','Current'),
 ('BK-M68B-42','Mountain-200 Black, 42',1,'Black','42',1251.98,2294.99,'Mountain-200','Current'),
 ('BK-M68S-46','Mountain-200 Silver, 46',1,'Silver','46',1265.62,2319.99,'Mountain-200','Current'),
 ('BK-R93R-44','Road-150 Red, 44',2,'Red','44',2171.29,3578.27,'Road-150','Current'),
 ('BK-R93R-48','Road-150 Red, 48',2,'Red','48',2171.29,3578.27,'Road-150','Current'),
 ('BK-R50B-52','Road-450 Blue, 52',2,'Blue','52',884.71,1457.99,'Road-450',NULL),
 ('BK-T79U-46','Touring-1000 Blue, 46',3,'Blue','46',1481.94,2384.07,'Touring-1000','Current'),
 ('BK-T79Y-50','Touring-1000 Yellow, 50',3,'Yellow','50',1481.94,2384.07,'Touring-1000','Current'),
 ('HL-U509-R','Sport-100 Helmet, Red',14,'Red','U',13.09,34.99,'Sport-100','Current'),
 ('HL-U509-B','Sport-100 Helmet, Black',14,'Black','U',13.09,34.99,'Sport-100','Current'),
 ('LJ-0192-S','Long-Sleeve Logo Jersey, S',31,'Multi','S',38.49,49.99,'Long-Sleeve Logo Jersey',NULL),
 ('LJ-0192-M','Long-Sleeve Logo Jersey, M',31,'Multi','M',38.49,49.99,'Long-Sleeve Logo Jersey','Current'),
 ('TT-T092','Touring Tire Tube',37,NULL,NULL,1.86,4.99,'Touring Tire Tube','Current'),
 ('TT-M928','Mountain Tire Tube',37,NULL,NULL,1.87,4.99,'Mountain Tire Tube','Current'),
 ('BK-M18B-40','Mountain-100 Black, 40',1,'Black','40',1898.09,3374.99,'Mountain-100',NULL),
 ('BK-M18S-44','Mountain-100 Silver, 44',1,'Silver','44',1912.15,3399.99,'Mountain-100','Current');
GO

-------------------------------------------------------------------------
-- dbo.DimProduct seed (so FactInternetSales lookups resolve ProductKey)
-------------------------------------------------------------------------
INSERT INTO dbo.DimProduct (ProductKey, ProductAlternateKey, EnglishProductName, ProductSubcategoryKey, Color, Size, StandardCost, ListPrice, ModelName, Status) VALUES
 (310,'BK-M68B-38','Mountain-200 Black, 38',1,'Black','38',1251.98,2294.99,'Mountain-200','Current'),
 (311,'BK-M68B-42','Mountain-200 Black, 42',1,'Black','42',1251.98,2294.99,'Mountain-200','Current'),
 (312,'BK-M68S-46','Mountain-200 Silver, 46',1,'Silver','46',1265.62,2319.99,'Mountain-200','Current'),
 (320,'BK-R93R-44','Road-150 Red, 44',2,'Red','44',2171.29,3578.27,'Road-150','Current'),
 (321,'BK-R93R-48','Road-150 Red, 48',2,'Red','48',2171.29,3578.27,'Road-150','Current'),
 (330,'BK-T79U-46','Touring-1000 Blue, 46',3,'Blue','46',1481.94,2384.07,'Touring-1000','Current'),
 (222,'HL-U509-R','Sport-100 Helmet, Red',14,'Red','U',13.09,34.99,'Sport-100','Current'),
 (223,'HL-U509-B','Sport-100 Helmet, Black',14,'Black','U',13.09,34.99,'Sport-100','Current'),
 (480,'TT-T092','Touring Tire Tube',37,NULL,NULL,1.86,4.99,'Touring Tire Tube','Current');
GO

-------------------------------------------------------------------------
-- dbo.DimGeography + dbo.DimCustomer seed (so sales lookups resolve)
-------------------------------------------------------------------------
INSERT INTO dbo.DimGeography (GeographyKey, City, StateProvinceName, EnglishCountryRegionName, PostalCode) VALUES
 (1,'Seattle','Washington','United States','98101'),
 (2,'Portland','Oregon','United States','97201'),
 (3,'San Francisco','California','United States','94109'),
 (4,'Toronto','Ontario','Canada','M4B 1B3'),
 (5,'London','England','United Kingdom','SW1A 1AA');
GO

INSERT INTO dbo.DimCustomer (CustomerKey, GeographyKey, CustomerAlternateKey, FirstName, LastName, FullName, BirthDate, MaritalStatus, Gender, EmailAddress, YearlyIncome, EnglishEducation) VALUES
 (11000,1,'AW00011000','Jon','Yang','Jon Yang','1971-10-06','M','M','jon24@adventure-works.com',90000,'Bachelors'),
 (11001,2,'AW00011001','Eugene','Huang','Eugene Huang','1976-05-10','S','M','eugene10@adventure-works.com',60000,'Bachelors'),
 (11002,3,'AW00011002','Ruben','Torres','Ruben Torres','1971-02-09','M','M','ruben35@adventure-works.com',60000,'Bachelors'),
 (11003,4,'AW00011003','Christy','Zhu','Christy Zhu','1973-08-14','S','F','christy12@adventure-works.com',70000,'Bachelors'),
 (11004,5,'AW00011004','Elizabeth','Johnson','Elizabeth Johnson','1979-08-05','S','F','elizabeth5@adventure-works.com',80000,'Bachelors');
GO

-------------------------------------------------------------------------
-- stg.Customer (~16 rows) — note dirty Gender/MaritalStatus to clean
-------------------------------------------------------------------------
INSERT INTO stg.Customer (CustomerAlternateKey, GeographyKey, FirstName, LastName, BirthDate, MaritalStatus, Gender, EmailAddress, YearlyIncome, EnglishEducation) VALUES
 ('AW00011005',1,'Julio','Ruiz','1976-08-01','Married','Male','julio1@adventure-works.com',70000,'Bachelors'),
 ('AW00011006',2,'Janet','Alvarez','1972-12-02','Single','Female','janet9@adventure-works.com',70000,'Bachelors'),
 ('AW00011007',3,'Marco','Mehta','1965-05-09','M','M','marco14@adventure-works.com',60000,'Graduate Degree'),
 ('AW00011008',4,'Rob','Verhoff','1964-07-07','S','F','rob4@adventure-works.com',60000,'Graduate Degree'),
 ('AW00011009',5,'Shannon','Carlson','1965-04-12','S','M','shannon38@adventure-works.com',70000,'Bachelors'),
 ('AW00011010',1,'Jacquelyn','Suarez','1964-05-12','Single','Female','jacquelyn20@adventure-works.com',70000,'Bachelors'),
 ('AW00011011',2,'Curtis','Lu','1969-11-04','M','Male','curtis17@adventure-works.com',60000,'Bachelors'),
 ('AW00011012',3,'Lauren','Walker','1977-08-12','Married','F','lauren41@adventure-works.com',100000,'Partial College'),
 ('AW00011013',4,'Ian','Jenkins','1977-01-23','M','M','ian47@adventure-works.com',100000,'Partial College'),
 ('AW00011014',5,'Sydney','Bennett','1977-07-08','S','Female','sydney23@adventure-works.com',100000,'Partial College'),
 ('AW00011015',1,'Chloe','Young','1973-05-01','Single','F','chloe23@adventure-works.com',30000,'Partial College'),
 ('AW00011016',2,'Wyatt','Hill','1968-12-26','M','M','wyatt35@adventure-works.com',30000,'High School'),
 ('AW00011017',3,'Shannon','Wang','1974-10-08','S','M','shannon3@adventure-works.com',40000,'High School'),
 ('AW00011018',4,'Clarence','Rai','1972-08-22','Married','Male','clarence37@adventure-works.com',40000,'High School'),
 ('AW00011019',5,'Luke','Lal','1975-02-15','S','M','luke18@adventure-works.com',40000,'Partial High School'),
 ('AW00011020',1,'Jordan','King','1969-07-29','Married','Male','jordan21@adventure-works.com',40000,'Partial High School');
GO

-------------------------------------------------------------------------
-- stg.SalesOnline (~14 rows)
-------------------------------------------------------------------------
INSERT INTO stg.SalesOnline (ProductAlternateKey, CustomerAlternateKey, SalesTerritoryKey, SalesOrderNumber, SalesOrderLineNumber, OrderQuantity, UnitPrice, ProductStandardCost, SalesAmount, TaxAmt, OrderDate) VALUES
 ('BK-M68B-38','AW00011000',1,'SO43697',1,1,2294.99,1251.98,2294.99,183.60,'2024-01-05'),
 ('BK-R93R-44','AW00011001',1,'SO43698',1,1,3578.27,2171.29,3578.27,286.26,'2024-01-07'),
 ('HL-U509-R','AW00011002',1,'SO43699',1,2,34.99,13.09,69.98,5.60,'2024-01-09'),
 ('BK-T79U-46','AW00011003',4,'SO43700',1,1,2384.07,1481.94,2384.07,190.73,'2024-01-12'),
 ('BK-M68S-46','AW00011004',5,'SO43701',1,1,2319.99,1265.62,2319.99,185.60,'2024-01-15'),
 ('TT-T092','AW00011000',1,'SO43702',1,4,4.99,1.86,19.96,1.60,'2024-02-02'),
 ('HL-U509-B','AW00011001',1,'SO43703',1,1,34.99,13.09,34.99,2.80,'2024-02-08'),
 ('BK-M68B-42','AW00011002',1,'SO43704',1,1,2294.99,1251.98,2294.99,183.60,'2024-02-14'),
 ('BK-R93R-48','AW00011003',4,'SO43705',1,1,3578.27,2171.29,3578.27,286.26,'2024-02-20'),
 ('BK-T79U-46','AW00011004',5,'SO43706',1,1,2384.07,1481.94,2384.07,190.73,'2024-03-01'),
 ('HL-U509-R','AW00011000',1,'SO43707',1,3,34.99,13.09,104.97,8.40,'2024-03-09'),
 ('BK-M68S-46','AW00011002',1,'SO43708',1,1,2319.99,1265.62,2319.99,185.60,'2024-03-15'),
 ('TT-T092','AW00011003',4,'SO43709',1,2,4.99,1.86,9.98,0.80,'2024-03-22'),
 ('BK-M68B-38','AW00011004',5,'SO43710',1,1,2294.99,1251.98,2294.99,183.60,'2024-03-28');
GO

-------------------------------------------------------------------------
-- stg.SalesReseller (~12 rows)
-------------------------------------------------------------------------
INSERT INTO stg.SalesReseller (ProductAlternateKey, CustomerAlternateKey, SalesTerritoryKey, SalesOrderNumber, SalesOrderLineNumber, OrderQuantity, UnitPrice, ProductStandardCost, SalesAmount, TaxAmt, OrderDate) VALUES
 ('BK-M68B-38','AW00011005',6,'SO45001',1,10,1376.99,1251.98,13769.90,1101.59,'2024-01-10'),
 ('BK-M68B-42','AW00011006',6,'SO45001',2,8,1376.99,1251.98,11015.92,881.27,'2024-01-10'),
 ('BK-R93R-44','AW00011007',7,'SO45002',1,5,2146.96,2171.29,10734.80,858.78,'2024-01-18'),
 ('BK-T79U-46','AW00011008',7,'SO45003',1,6,1430.44,1481.94,8582.64,686.61,'2024-01-25'),
 ('HL-U509-R','AW00011009',6,'SO45004',1,50,20.99,13.09,1049.50,83.96,'2024-02-05'),
 ('HL-U509-B','AW00011010',6,'SO45004',2,50,20.99,13.09,1049.50,83.96,'2024-02-05'),
 ('TT-T092','AW00011011',8,'SO45005',1,100,2.99,1.86,299.00,23.92,'2024-02-15'),
 ('BK-M68S-46','AW00011012',8,'SO45006',1,7,1391.99,1265.62,9743.93,779.51,'2024-02-22'),
 ('BK-R93R-48','AW00011013',7,'SO45007',1,4,2146.96,2171.29,8587.84,687.03,'2024-03-04'),
 ('LJ-0192-M','AW00011014',6,'SO45008',1,25,29.99,38.49,749.75,59.98,'2024-03-12'),
 ('LJ-0192-S','AW00011015',6,'SO45008',2,20,29.99,38.49,599.80,47.98,'2024-03-12'),
 ('BK-M68B-38','AW00011016',8,'SO45009',1,9,1376.99,1251.98,12392.91,991.43,'2024-03-20');
GO
