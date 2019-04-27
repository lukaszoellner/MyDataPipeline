# PREPARATION ================================================================================================
# Install packages
# ----------------

# Drop all existing variables
rm(list = ls())

# Load Libraries
library(RSQLite)
library(DBI)
library(data.table)
library(here)
library(odbc)
library(httr)
library(ff)
library(pryr)
library(plyr)
library(knitr)

# Automatically set working directory with the here() function
setwd(here())
getwd()

# Connect with database
fec <- dbConnect(SQLite(), dbname= "./data/fec.sqlite")

# Table 1 ====================================================================================================

# Define queries
# Querie asks for spendings of OIL&GAS industry. Only look at years between 1990 - 2014
my_query_1 <- "SELECT
                strftime(\"%Y\", date) as \"year\", SUM(amount)
              FROM
                donations
              JOIN
                industrycodes ON donations.contributor_category = industrycodes.code
              JOIN
                transactiontypes ON donations.transaction_type = transactiontypes.Transaction_Types
              WHERE
                industrycodes.industry = \"OIL & GAS\"
              AND
                transactiontypes.Transaction_Types_Description =
                \"Contribution to political committees (other than Super PACs and Hybrid PACs) from an individual, partnership or limited liability company\"
              AND
                year BETWEEN \"1988-12-31\" AND \"2014-12-31\"
              GROUP
                BY year"

# Querie asks for spendings of ALL industries. Only look at years between 1990 - 2014
my_query_2 <- "SELECT
                strftime(\"%Y\", date) as \"year\", SUM(amount)
              FROM
                donations
              JOIN
                transactiontypes ON donations.transaction_type = transactiontypes.Transaction_Types
              WHERE
                transactiontypes.Transaction_Types_Description =
                \"Contribution to political committees (other than Super PACs and Hybrid PACs) from an individual, partnership or limited liability company\"
              AND
                year BETWEEN \"1988-12-31\" AND \"2014-12-31\"
              GROUP BY
                year"


# Issue queries OIL & GAS (2014 has no entry. Set to 2014 to 0 so that percentages_df has equal length)
df_oil <- dbGetQuery(fec, my_query_1)
df_oil <- rbind(df_oil, c(2014, 0))

# Issue queries Total amount spent
df_total <- dbGetQuery(fec, my_query_2)

# Create Output Table and calculate Percentage values
df_percentages <- round((100*(df_oil[,2]/df_total[,2])), 2)
df_combined <- cbind(df_total, df_oil[,2], df_percentages)
colnames(df_combined) <- c("Year", "TOTAL donations", "O&G Industry donations", "Percentages")
df_combined
rm(my_query_1, my_query_2, df_oil, df_total, df_percentages)
gc()

# Table 2 ====================================================================================================

my_query_3 <- "SELECT
            cycle, recipient_name, SUM(amount) as money
          FROM
            donations
          WHERE
            seat = \"federal:president\"
          AND
            recipient_type = \"P\"
          AND
            amount >= 0
          GROUP BY
            cycle, recipient_name
          ORDER BY
            cycle, money DESC"

# Store output in dataframe (since the output is extremely small we can us a data.frame instead of a data.table here)
df_ranking <- dbGetQuery(fec, my_query_3)
df_ranking <- df_ranking[,1:2]

# Create a ranking and assign a ranking to each candidate in each year
df_ranking<- ddply(df_ranking, .(cycle), mutate, rank = seq_along(recipient_name))

# Transform data from long to wide format, slice out the first 5 candidates each year and rename columns
df_ranking_wide <- reshape(df_ranking, idvar = "rank", timevar = "cycle", direction = "wide")
df_ranking_wide <- df_ranking_wide[1:5, ]
colnames_years <- seq(1990, 2014, 2)
colnames(df_ranking_wide) <- c("Rank", colnames_years) 
df_ranking_wide
rm(my_query_3, df_ranking, colnames_years)
gc()

# TABLE 3 ====================================================================================================

# Create query (We allow for negative amounts since the Task does not specify something different)
my_query_4 <- "SELECT
                strftime(\"%Y\", date) as \"year\",
              COUNT
                (CASE WHEN industrycodes.industry = \"BUSINESS ASSOCIATIONS\" THEN amount ELSE NULL END) AS \"BUSINESS ASSOCIATIONS\",
              COUNT
                (CASE WHEN industrycodes.industry = \"PUBLIC SECTOR UNIONS\" THEN amount ELSE NULL END) AS \"PUBLIC SECTOR UNIONS\",
              COUNT
                (CASE WHEN industrycodes.industry = \"INDUSTRIAL UNIONS\" THEN amount ELSE NULL END) AS \"INDUSTRIAL UNIONS\",
              COUNT
                (CASE WHEN industrycodes.industry = \"NON-PROFIT INSTITUTIONS\" THEN amount ELSE NULL END) AS \"NON-PROFIT INSTITUTIONS\",
              COUNT
                (CASE WHEN industrycodes.industry = \"RETIRED\" THEN amount ELSE NULL END) AS \"RETIRED\"
              FROM
                (donations JOIN industrycodes ON industrycodes.code = donations.contributor_category)
              WHERE
                year BETWEEN \"1988-12-31\" AND \"2014-12-31\"
              AND
                contributor_type = \"I\"
              AND
                amount < 1000
              GROUP
                BY year"


# Issue query
df_4 <- dbGetQuery(fec, my_query_4)

# Show data frame and show time
kable(df_4)

# Write data frame df_4 on hard drive as a .csv for Task 4
fwrite(df_4, file = "./data/df_Task_4.csv")
rm(my_query_4)
# Finish =======================================================================================================

# Disconnect from Database
dbDisconnect(fec)

# Report
rm(list = ls())
gc()
print("Part I Task 3 completed")

# ====================



df_neu <- fread("./data/df_Task_4.csv")
df_neu



