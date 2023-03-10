
--Energy_Plant_Data_Analytics--

select * from [dbo].[Customers]

ALTER TABLE [dbo].[Customers]
ALTER COLUMN [Customer ID] NVARCHAR(50) NOT NULL;

ALTER TABLE [dbo].[Energy Plants]
ALTER COLUMN [Plant ID] NVARCHAR(50) NOT NULL;

ALTER TABLE [dbo].[Energy Plants]
ALTER COLUMN [Fuel ID] NVARCHAR(50) NOT NULL;

ALTER TABLE [dbo].[Energy Sales Transactions]
ALTER COLUMN [Customer ID] NVARCHAR(50) NOT NULL;

ALTER TABLE [dbo].[Energy Sales Transactions (PK)]
ALTER COLUMN [PK - Sales Transactions] INT NOT NULL;

ALTER TABLE [dbo].[Energy Sales Transactions (PK)]
ALTER COLUMN [Plant ID] NVARCHAR(50) NOT NULL;

ALTER TABLE [dbo].[Energy Sales Transactions]
ALTER COLUMN [Fuel ID] NVARCHAR(50) NOT NULL;

ALTER TABLE [dbo].[Fuel]
ALTER COLUMN [Fuel ID] NVARCHAR(50) NOT NULL



/*If we look at the ‘Energy Sales Transaction’ table in the table schema, we will
notice that there is no primary key!
This is not a problem; we can use the row number SQL window function to
create a synthetic primary key
Each row of data will be given a unique row number, so it solves our issue*/

SELECT ROW_NUMBER() OVER (ORDER BY [Customer ID]) AS [PK - Sales Transactions]
,*
INTO [dbo].[Energy Sales Transactions (PK)]
FROM [dbo].[Energy Sales Transactions]

select * from [dbo].[Energy Sales Transactions (PK)]

--In this case study, there is more than one table which has a foreign key which is not the primary key

ALTER TABLE[dbo].[Customers]
ADD PRIMARY KEY ([Customer ID]);

ALTER TABLE [dbo].[Energy Plants]
ADD PRIMARY KEY ([Plant ID]);

ALTER TABLE [dbo].[Energy Sales Transactions (PK)]
ADD PRIMARY KEY ([PK - Sales Transactions]);

ALTER TABLE [dbo].[Fuel]
ADD PRIMARY KEY ([Fuel ID]);

ALTER TABLE [dbo].[Energy Sales Transactions (PK)]
ADD FOREIGN KEY ([Customer ID])
REFERENCES [dbo].[Customers]([Customer ID]);

ALTER TABLE [dbo].[Energy Sales Transactions (PK)]
ADD FOREIGN KEY ([Plant ID])
REFERENCES [dbo].[Energy Plants]([Plant ID]);

ALTER TABLE [dbo].[Energy Sales Transactions (PK)]
ADD FOREIGN KEY ([Fuel ID])
REFERENCES [dbo].[Fuel]([Fuel ID]);

ALTER TABLE [dbo].[Energy Plants]
ADD FOREIGN KEY ([Fuel ID])
REFERENCES [dbo].[Fuel]([Fuel ID])

---------------

SELECT A.[PK - Sales Transactions]
,A.[Customer ID]
,B.[Customer Name]
,B.[Green Rating]
,B.[Customer Satisfaction]
,B.[Sanctions]
,A.[Plant ID]
,C.[Plant Name]
,C.[Commission Year]
,A.[Fuel ID]
,D.[Fuel Name]
,D.[Fuel Type]
,D.[Pollution Index]
,D.[Price Per Unit ($ kW-hr)]
,A.[Quantity of Fuel Units (Millions)]
INTO [Energy Plant - Master]
FROM [dbo].[Energy Sales Transactions (PK)] AS A
LEFT JOIN [dbo].[Customers] AS B
ON A.[Customer ID] = B.[Customer ID]
LEFT JOIN [dbo].[Energy Plants] AS C
ON A.[Plant ID] = C.[Plant ID]
LEFT JOIN [dbo].[Fuel] AS D
ON A.[Fuel ID] = D.[Fuel ID]

--Sub-querying is used to show the transaction summary for each fuel type. 
--Sub-querying was used as the ‘Total Cost’ needs to be calculated before it can be used in our analysis.

SELECT A.[Fuel Type]
,A.[Fuel Name]
,A.[Total Cost]
,A.[Number of Transactions]
,CAST( AVG([Total Cost]) AS DECIMAL(18,2)) AS [Cost Average]
FROM
   (  SELECT [Fuel Type]
			,[Fuel Name]
			,SUM( CAST([Quantity of Fuel Units (Millions)] AS INT) *
			CAST([Price Per Unit ($ kW-hr)] AS DECIMAL(18,3)) ) AS [Total Cost]
			,COUNT(*) AS [Number of Transactions]
			FROM [dbo].[Energy Plant - Master]
			GROUP BY [Fuel Type]
				    ,[Fuel Name]
	)A
GROUP BY A.[Fuel Type]
,A.[Fuel Name]
,A.[Total Cost]
,A.[Number of Transactions]

--The plants and the fuel used can be analysed for the transactions that took place. 
--Adding additional columns such as the ‘Pollution Index’ and ‘Commission Year’ adds more depth to our analysis.

SELECT [Plant ID]
,[Plant Name]
,[Fuel ID]
,[Fuel Name]
,[Commission Year]
,[Pollution Index]
,COUNT(*) AS [No. Transactions]
FROM [dbo].[Energy Plant - Master] 
GROUP BY [Plant ID]
,[Plant Name]
,[Fuel ID]
,[Fuel Name]
,[Commission Year]
,[Pollution Index]

--This query will be used as the core part of the query which will in turn
--be used as the foundation for the advanced customer summary


SELECT [Customer ID]
,[Customer Name]
,[Green Rating]
,[Customer Satisfaction]
,[Sanctions]
,[Fuel Type]
,COUNT(*) AS [No. Transactions]
,SUM( CAST([Quantity of Fuel Units (Millions)] AS INT) *
CAST([Price Per Unit ($ kW-hr)] AS DECIMAL(18,3)) ) AS [Total Cost]
FROM [dbo].[Energy Plant - Master] 
GROUP BY [Customer ID]
,[Customer Name]
,[Green Rating]
,[Customer Satisfaction]
,[Sanctions]
,[Fuel Type]
ORDER BY [Customer ID]


/*1.We will sub-query the previous query to produce the advanced
customer summary list
 2.The ‘Customer Total’ field is created by using a window function
without the ‘ORDER BY’ statement being present. This creates a
column for the total value instead of a running total
 3. A calculated field ‘Total Cost’ is created and from this we will
create the following fields which enhance our analytics:
 4.Running total
 5.Percentage of the total transaction cost for each customer split by
‘Renewable’ and ‘Non-renewable’ energy sources*/

SELECT *
,SUM([Total Cost]) OVER (PARTITION BY [Customer ID] ORDER BY [Fuel Type]) AS [Running Total]
,SUM([Total Cost]) OVER (PARTITION BY [Customer ID]) AS [Customer Total]
,CAST( ([Total Cost] / SUM([Total Cost]) OVER (PARTITION BY [Customer ID]) ) AS DECIMAL(18,2)) AS [Percentage]
FROM
  (SELECT [Customer ID]
		,[Customer Name]
		,[Green Rating]
		,[Customer Satisfaction]
		,[Sanctions]
		,[Fuel Type]
		,COUNT(*) AS [No. of Transactions]
		,SUM( CAST([Quantity of Fuel Units (Millions)] AS INT) *
		CAST([Price Per Unit ($ kW-hr)] AS DECIMAL(18,3)) ) AS [Total Cost]
		FROM [dbo].[Energy Plant - Master] 
		GROUP BY [Customer ID]
		,[Customer Name]
		,[Green Rating]
		,[Customer Satisfaction]
		,[Sanctions]
		,[Fuel Type])A
ORDER BY [Customer ID]