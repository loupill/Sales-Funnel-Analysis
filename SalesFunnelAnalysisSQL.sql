-- 1. Compute the attach rate on deals (% of deals that have SAs engaged, and the dollar amount of deals)
-- Create CTE to find total count of opps with SAs as well as the total dollar amount of those opportunities
WITH SA_Opps AS (
	SELECT 
		COUNT(DISTINCT od.Opportunity_Name) as CountOppsWithSA, 
		SUM(od.Amount) as OppsWithSADollarAmt
	FROM dbo.OppData od
	JOIN dbo.SA_Data sd
	ON sd.Opportunity_Name = od.Opportunity_Name),
-- Create another CTE for total count of opps with or without SAs and the total dollar amount of all those opportunities
TotalOpps AS (
SELECT 
	COUNT(DISTINCT od.Opportunity_Name) as TotalOpps, 
	SUM(od.Amount) AS TotalDollarAmt
FROM dbo.OppData od
LEFT JOIN dbo.SA_Data sd
ON sd.Opportunity_Name = od.Opportunity_Name)

-- Use the derived columns from those tables to get our SA attach rate and % of total dollar amount those opportunities make up
SELECT
	t.TotalOpps,
	t.TotalDollarAmt,
	sa.CountOppsWithSA,
	sa.OppsWithSADollarAmt,
	CAST(sa.CountOppsWithSA AS DECIMAL(18,2))/ CAST(t.TotalOpps AS DECIMAL(18,2)) * 100 AS AttachRate,
	sa.OppsWithSADollarAmt / t.TotalDollarAmt * 100 AS AttacheRate$

FROM
	TotalOpps t,
	SA_Opps sa;
--Findings: About 77.5% of deals have SAs attached and those deals make up about 76.2% of total pipeline $


-- 2. Compute the win rate of deals (number of Live deals/(number of live + lost deals)) with and without SAs
-- Join Opps data and SA Data
WITH AllOppsAndSAData AS(
	SELECT 
		od.Opportunity_Name,
		od.Stage,
		sd.SA_Name
	FROM dbo.OppData od
	LEFT JOIN dbo.SA_Data sd
	ON od.Opportunity_Name = sd.Opportunity_Name),
-- Get counts of Opps with SAs attached grouped by stage
StageWithSA AS (
	SELECT 
		Stage, 
		COUNT(DISTINCT Opportunity_Name) as OppsWithSACount
	FROM AllOppsAndSAData
	WHERE SA_Name IS NOT NULL
	GROUP BY Stage),
-- Get counts of Opps without SAs attached grouped by stage
StageWithoutSA AS (
	SELECT 
		Stage, COUNT(DISTINCT Opportunity_Name) as OppsWithoutSACount
	FROM AllOppsAndSAData
	WHERE SA_Name IS NULL
	GROUP BY Stage)
-- Use the counts returned from our two CTEs to calculate rates
SELECT 
	-- Win rate with SA attached
	(SELECT CAST(OppsWithSACount AS DECIMAL (18,2)) FROM StageWithSA WHERE Stage = 'Live') / 
	((SELECT CAST(OppsWithSACount AS DECIMAL (18,2)) FROM StageWithSA WHERE Stage = 'Live') + (SELECT CAST(OppsWithSACount AS DECIMAL (18,2)) FROM StageWithSA WHERE Stage = 'Lost')) * 100 AS WinRateWithSA,
	-- Win rate without SA attched
	(SELECT CAST(OppsWithoutSACount AS DECIMAL (18,2)) FROM StageWithoutSA WHERE Stage = 'Live') / 
	((SELECT CAST(OppsWithoutSACount AS DECIMAL (18,2)) FROM StageWithoutSA WHERE Stage = 'Live') + (SELECT CAST(OppsWithoutSACount AS DECIMAL (18,2)) FROM StageWithoutSA WHERE Stage = 'Lost')) * 100 AS WinRateWithoutSA;
-- Findings: There is a negligable difference (quarter of a percent) in the win rates when SA are involved (17.95%) vs not involved (17.725%)


-- 3. Compute the average amount per deal with and without SAs
WITH AvgDealSizeWithSA AS (
	SELECT 
		AVG(od.Amount) AS AvgAmountWithSA
	FROM OppData od
	JOIN SA_Data sd
	ON sd.Opportunity_Name = od.Opportunity_Name),
AvgDealSizeWithoutSA AS (
	SELECT 
		AVG(od.Amount) AS AvgAmountWithoutSA
	FROM OppData od
	LEFT JOIN SA_Data sd
	ON od.Opportunity_Name = sd.Opportunity_Name
	WHERE sd.SA_Name IS NULL)
SELECT 
	AvgAmountWithSA,
	AvgAmountWithoutSA
FROM 
	AvgDealSizeWithSA,
	AvgDealSizeWithoutSA;
-- Findings: On average deals are almost $1mil lower when SAs are involved -- This is something to look into

-- 4. Compute ProServ or Partner attach rate with and without SAs
-- Get a table of all opps with SA and ProServ data
WITH ProServAndSAData AS (
	SELECT 
		od.Opportunity_Name, 
		sd.SA_Name, 
		ps.ProServ,
		ps.Partner
	FROM OppData od
	LEFT JOIN SA_Data sd
	ON od.Opportunity_Name = sd.Opportunity_Name
	LEFT JOIN ProServPartnerData ps
	ON ps.Opportunity_Name = od.Opportunity_Name),
-- Create table to identify opps with ProServ/Partner as well as identify opps with SAs involved
FlagCTE AS (
	SELECT
		CASE
			WHEN ProServ = 'Y' OR Partner = 'Y' THEN 1
			ELSE 0
		END AS PartnerOrProServFlag,
		CASE
			WHEN SA_Name IS NOT NULL THEN 'SA Involved'
			ELSE 'No SA Involved'
		END AS SAFlag
	FROM ProServAndSAData),
-- Create table to count the number of opps by our SA Flag when there is a Partner or ProServ is involved
OppsWithProServOrPartnerAndSA AS (
	SELECT 
		SAFlag,
	COUNT(*) AS OppCount
	FROM FlagCTE
	WHERE PartnerOrProServFlag = 1
	GROUP BY SAFlag),
-- Get the total count of opps with SA involved vs not involved to use for our calculation
OppCountBySAs AS (	
SELECT
	CASE 
		WHEN SA_Name IS NOT NULL THEN 'SA Involved'
		ELSE 'No SA Involved'
	END AS SAFlag,
	COUNT(*) AS OppCount
FROM ProServAndSAData
GROUP BY 
	CASE 
		WHEN SA_Name IS NOT NULL THEN 'SA Involved'
		ELSE 'No SA Involved'
	END)
-- Finally, calculate the attach rates
SELECT
	(SELECT CAST(OppCount AS DECIMAL(18,2)) FROM OppsWithProServOrPartnerAndSA WHERE SAFlag = 'SA Involved') /
	(SELECT CAST(OppCount AS DECIMAL(18,2)) FROM OppCountBySAs WHERE SAFlag = 'SA Involved') * 100 AS AttachRateWithSA,
	(SELECT CAST(OppCount AS DECIMAL(18,2)) FROM OppsWithProServOrPartnerAndSA WHERE SAFlag = 'No SA Involved') / 
	(SELECT CAST(OppCount AS DECIMAL(18,2)) FROM OppCountBySAs WHERE SAFlag = 'No SA Involved') * 100 AS AttachRateWithoutSA; 
-- Findings: Attach rate is about 10.5% higher when SAs are not involved



-- 5. Diagnose where there may be opportunities to improve productivity for the SAs as well as Sales orgs

--Find the pipeline stage where most deals are falling through and which SAs are attached to those deals if any
--Create table with flag of when deals were lost along with the SA information if any is present
WITH OppsWithLastStageReached AS (
	SELECT 
	od.Opportunity_Name,
	CASE 
		WHEN Reached_Stage_Discovering_Needs = 1 AND Reached_Stage_Mutually_Educating = 0 THEN 'Lost @ Discovery'
		WHEN Reached_Stage_Mutually_Educating  = 1 AND Reached_Stage_Validating_Fit  = 0 THEN 'Lost @ Educating'
		WHEN Reached_Stage_Validating_Fit = 1 AND Reached_Stage_Negotiating = 0 THEN 'Lost @ Validating Fit'
		WHEN Reached_Stage_Negotiating = 1 AND Reached_Stage_Onboarding = 0 THEN 'Lost @ Negotiations'
		WHEN Reached_Stage_Onboarding = 1 AND Reached_Stage_Live_Closed_Won = 0 THEN 'Lost @ Onboarding'
		ELSE 'Closed Won'
	END AS StageLost,
	od.Amount,
	sd.SA_Name
	FROM OppData od
	LEFT JOIN SA_Data sd
	ON od.Opportunity_Name = sd.Opportunity_Name), 
-- Create table to rank the stages where deals were lost by each SA 
RankStagesLostWithSA AS (
	SELECT 
		StageLost, 
		COALESCE(SA_Name, 'No SA Involved') AS SA_Involved, 
		COUNT(*) AS CountOpps, 
		CAST(SUM(Amount) AS MONEY) AS TotalOppAmount,
		ROW_NUMBER() OVER (PARTITION BY COALESCE(SA_Name, 'No SA Involved') ORDER BY COUNT(*) DESC) AS TopLostStage
	FROM OppsWithLastStageReached
	GROUP BY SA_Name, StageLost),
--Create the same table but only group by Stage Lost without SA data
RankStagesLost AS (
	SELECT
		StageLost, 
		COUNT(*) AS CountOpps, 
		CAST(SUM(Amount) AS MONEY) AS TotalOppAmount,
		ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS TopLostStage
	FROM OppsWithLastStageReached
	GROUP BY StageLost)
-- Get the top two stages where deals were lost for each SA 
/*SELECT *
FROM RankStagesLostWithSA
WHERE TopLostStage <= 2 */
-- Get the stages where deals were lost without SA data
SELECT *
FROM RankStagesLost;


-- Find if SAs are helping to close deals faster in particular segments or verticals
-- Create table of Live Opportunities and the SAs involved if any
WITH AllOppsAndSAData AS (
	SELECT od.Opportunity_Name, 
		DATEDIFF(DAY, od.Created_Date,  od.Close_Date) AS DaysToClose, 
		od.Vertical,
		od.Segment,
		sd.SA_Name
	FROM OppData od
	LEFT JOIN SA_Data sd
	ON od.Opportunity_Name = sd.Opportunity_Name
	WHERE Stage = 'Live'),
-- Create a flag to identify if SA is involved as well as a column signifying the overall average age by if a SA is involved or not, this will be used to compare how SAs are affecting each vertical and segment's time to close
OppsBySAStatus AS (
	SELECT *,
		CASE
			WHEN SA_Name IS NOT NULL THEN 'SA Involved'
			ELSE 'No SA Involved'
		END as SAStatus,
	AVG(DaysToClose) OVER (PARTITION BY CASE WHEN SA_Name IS NOT NULL THEN 'SA Involved' ELSE 'No SA Involved' END) AS AvgDaysToCloseBySAStatus
	FROM AllOppsAndSAData)
-- Get the average Days to close by vertical and SA status
/*SELECT 
	AVG(DaysToClose) AS AvgDaysToClose, 
	COUNT(*) AS CountOfOpps,
	SAStatus,
	Vertical,
	AvgDaysToCloseBySAStatus
FROM OppsBySAStatus
GROUP BY SAStatus, Vertical, AvgDaysToCloseBySAStatus
ORDER BY Vertical, SAStatus;*/
/*-- Findings: There is a negligable difference (roughly 1 to 2 days) in Days To Close between verticals based on SA involvement compared to the mean DaysToClose across all opps by SA status. 
This may be a fairly natural correlaton since SAs may be getting involved to talk to more technical members of the purchasing company to discuss processes such as integrations, etc. */
-- Get the average Days to close by Segment and SA status
SELECT 
	AVG(DaysToClose) AS AvgDaysToClose,
	COUNT(*) AS CountOfOpps,
	SAStatus,
	Segment,
	AvgDaysToCloseBySAStatus
FROM OppsBySAStatus
GROUP BY SAStatus, Segment, AvgDaysToCloseBySAStatus
ORDER BY Segment, SAStatus;
--Findings: Again we see a negligable difference in Days To Close when SA is involved vs not involved - however we see the sales cycle for late startup segment is almost double that of growth segment


-- Find out how SAs are impacting high value deals
-- For this use case we will define a high value deal as the top quartile of deals
-- Create a table bucketing the deals into their respective quartile based on Opp Amounts
WITH BucketedOppAmounts AS (
	SELECT od.Opportunity_Name, 
		od.Stage,
		od.Amount,
		CASE
			WHEN SA_Name IS NOT NULL THEN 'SA Involved'
			ELSE 'No SA Involved'
		END AS SAStatus, 
		NTILE(4) OVER (ORDER BY Amount ASC) AS AmountBucket
	FROM OppData od
	LEFT JOIN SA_Data sd
	ON od.Opportunity_Name = sd.Opportunity_Name),
-- Create table with count of high value opportunities lost and won by SA involvement
HighValueOppsWithSAStatus AS (
	SELECT 
		SAStatus,
		Stage,
		COUNT(*) AS OppCount	
	FROM BucketedOppAmounts
	WHERE AmountBucket = 4
	GROUP BY SAStatus, Stage),
-- Aggregate total opportunities for each SA Status
TotalOpps AS (
	SELECT 
		SAStatus,
		SUM(OppCount) AS TotalOppCount
	FROM HighValueOppsWithSAStatus
	GROUP BY SAStatus)
-- Calculate win rate when SA involved vs not involved
SELECT 
	hv.SAStatus,
	hv.Stage,
	hv.OppCount,
	CAST(hv.OppCount AS DECIMAL(18,2))/ CAST(t.TotalOppCount AS DECIMAL(18,2)) * 100 AS WinLossRate
FROM HighValueOppsWithSAStatus hv
JOIN TotalOpps t
ON hv.SAStatus = t.SAStatus
-- Findings: Only about a 1.6% difference in win rates when SAs are involved.



-- Inspect how technical fit and stage corrlate
WITH OppCountByTechnicalFit AS (
	SELECT 
		Technical_Fit,
		COUNT(*) OppCountByTechFit
		FROM SA_Data
		GROUP BY Technical_Fit),
-- Intererstingly all technical fit categories have the same opp count
-- Create table to get count of opps grouped by stage and technical fit
OppCountByStageAndTechFit AS (
	SELECT
		od.Stage,
		sd.Technical_Fit,
		COUNT(od.Opportunity_Name) AS OppCountByTechFitAndStage
	FROM OppData od
	JOIN SA_Data sd
	ON od.Opportunity_Name = sd.Opportunity_Name
	GROUP BY od.Stage, sd.Technical_Fit)
SELECT 
	a.Stage,
	a.Technical_Fit,
	a.OppCountByTechFitAndStage,
	b.OppCountByTechFit
FROM OppCountByStageAndTechFit a
JOIN OppCountByTechnicalFit b
ON a.Technical_Fit = b.Technical_Fit
ORDER BY a.Technical_Fit 
-- Finding: As assumed, a won techfit indicates a high likelihood that the opportunity will be won


--Find average deal amount across segments
SELECT
	Segment,
	AVG(Amount) AS AverageDealAmount
FROM OppData
GROUP BY Segment
ORDER BY Segment
-- Findings: Late Stage has the largest deal size by far ($36.6m). Almost 2.5x that of the second ranked segment, Growth