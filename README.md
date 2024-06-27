# Sales Funnel Analysis

## Project Overview
This project analyzes sales data to understand how Solutions Architects (SAs) are interacting with and affecting the sales process. The goal is to derive insights on the effectiveness of SA involvement in various stages of the sales pipeline, win rates, deal sizes, and other key metrics. The analysis is based on SQL queries executed on the company's sales data, with visualizations created using the Plotly Python package.

Objectives
1. Compute the Attach Rate on Deals:
- Goal: Determine the percentage of deals that have SAs engaged and the dollar amount of those deals.
- Findings: About 77.5% of deals have SAs attached, making up about 76.2% of the total pipeline value.

2. Compute the Win Rate of Deals with and without SAs:
- Goal: Calculate the win rate (number of live deals/(number of live + lost deals)) for deals with and without SAs.
- Findings: There is a negligible difference in win rates with SA involvement (17.95%) versus without (17.725%).

3. Compute the Average Amount per Deal with and without SAs:
- Goal: Compare the average deal amount for deals with SAs versus those without.
- Findings: Deals are almost $1 million lower on average when SAs are involved, indicating a potential area for investigation.

4.Compute ProServ or Partner Attach Rate with and without SAs:
- Goal: Determine the attach rate of Professional Services (ProServ) or Partners in deals with and without SAs.
- Findings: The attach rate is about 10.5% higher when SAs are not involved.

5. Diagnose Opportunities to Improve Productivity for SAs and Sales Orgs:
- Goal: Identify the pipeline stages where most deals are lost and assess if SAs are associated with these stages.
- Findings: Analysis of stages where deals are lost to identify areas for improvement.

6. Evaluate SAs' Impact on Closing Deals Faster in Specific Segments or Verticals:
- Goal: Analyze if SAs help close deals faster in particular segments or verticals.
- Findings: Negligible difference (1-2 days) in closing times between verticals based on SA involvement.

7. Assess SAs' Impact on High-Value Deals:
- Goal: Analyze how SAs impact high-value deals, defined as those in the top quartile by deal amount.
- Findings: Only about a 1.6% difference in win rates when SAs are involved.

8. Inspect the Correlation between Technical Fit and Stage:
- Goal: Determine how technical fit categories correlate with different stages of the sales process.
- Findings: High technical fit correlates with a higher likelihood of opportunity success.

9.Analyze Average Deal Amount Across Segments:
- Goal: Calculate the average deal amount across different sales segments.
- Findings: Late Stage segment has the largest deal size, almost 2.5 times that of the Growth segment.


## Methodology
The analysis involved running a series of SQL queries on the company's sales data. The resulting data was used to create visualizations and derive insights. Below are the key aspects analyzed and the respective SQL queries used:

1. Attach Rate on Deals:
- Calculated the percentage of deals with SAs involved and their dollar amount.

2. Win Rate with and without SAs:
- Computed win rates for deals with and without SA involvement.

3. Average Deal Amount with and without SAs:
- Compared average deal sizes for deals with SAs versus without.

4. ProServ or Partner Attach Rate:
- Determined attach rates for ProServ or Partner with and without SA involvement.

5. Pipeline Stage Analysis:
- Identified pipeline stages where deals are lost and associated SA involvement.

6.Closing Deals Faster in Segments/Verticals:
-Analyzed if SA involvement helps in closing deals faster in specific segments or verticals.

7.Impact on High-Value Deals:
- Evaluated the impact of SAs on high-value deals (top quartile by deal amount).

8. Technical Fit Correlation:
- Investigated how technical fit categories correlate with sales stages.

9. Average Deal Amount Across Segments:
- Calculated average deal amounts for different sales segments.


## Visualizations
Visualizations were created using Tableau as well as the Plotly Python package based on the data from the SQL queries. These visualizations help illustrate the key findings and insights from the analysis.

Conclusion
This analysis provides a comprehensive understanding of the impact of Solutions Architects on the sales process. The insights derived can be used to optimize SA involvement, improve win rates, and enhance overall sales productivity.

For detailed SQL queries and Python code used for visualization, please refer to the corresponding sheets and slide deck in the project repository.
