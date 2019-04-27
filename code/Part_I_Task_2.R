# PREPARATION ================================================================================================

# Install packages. Uncomment commands if needed

#install.packages("data.table")
#install.packages("rvest")
#install.packages("httr")
#install.packages("utils")
#install.packages("here")
#install.packages("RSQLite")
#install.packages("DBI")
#install.packages("ff")
#install.packages("ffbase")
#install.packages("pryr")


# Drop all existing variables
rm(list = ls())

# Load libraries
library(data.table)
library(rvest)
library(httr)
library(utils)
library(here)
library(RSQLite)
library(DBI)
library(ff)
library(ffbase)
library(pryr)

# Dynamically set working directory to top folder of project. Do not paste your own wd in here
setwd(here())
getwd()

# ============================================================================================================



# Create Database and Table "donations" ======================================================================

# Create Database fecsqlite. It will contain all three tables
fecsqlite <- dbConnect(SQLite(), "./data/fec.sqlite")

# Count rows of fec.csv, define batch size and calculate number of batches
data_path <- "./data/fec.csv"
start_time2 <- Sys.time()
nrows <-  length(count.fields("./data/fec.csv"))
end_time2 <- Sys.time()
time_elapsed2 <- end_time2 - start_time2
print(paste0("Time taken for counting the rows in .csv file: ", round(time_elapsed2, 2), " minutes"))
max_batchsize <- 600000
batches <- round(nrows/max_batchsize)

# Define field.types of donations, CHECK: date, 
donations_dtyps <- c(id="INTEGER", import_reference_id="INTEGER", cycle="INTEGER", transaction_namespace="TEXT", transaction_id="TEXT"
                     ,transaction_type="TEXT",filing_id="INTEGER",is_amendment="TEXT",amount="REAL",date="TEXT",contributor_name="TEXT"
                     ,contributor_ext_id="TEXT",contributor_type="TEXT",contributor_occupation="TEXT",contributor_employer="TEXT"
                     ,contributor_gender="TEXT",contributor_address="TEXT",contributor_city="TEXT",contributor_state="TEXT"
                     ,contributor_zipcode="INTEGER",contributor_category="TEXT",organization_name="TEXT",organization_ext_id="TEXT"
                     ,parent_organization_name="TEXT",parent_organization_ext_id="TEXT",recipient_name="TEXT",recipient_ext_id="TEXT"
                     ,recipient_party="TEXT",recipient_type="TEXT",recipient_state="TEXT",recipient_state_held="TEXT"
                     ,recipient_category="TEXT",committee_name="TEXT",committee_ext_id="TEXT",committee_party="TEXT",candidacy_status="TEXT"
                     ,district="TEXT",district_held="TEXT",seat="TEXT",seat_held="TEXT",seat_status="TEXT",seat_result="TEXT")


# Load batch with headings and write to database individually before the loop starts
first_batch <- fread(data_path, nrows = max_batchsize, header = TRUE)
column_names <- colnames(first_batch)
dbWriteTable(fecsqlite, "donations", field.types = donations_dtyps, overwrite = TRUE, first_batch)
rm(first_batch)
gc()

# Measure time before loop starts
start_time3 <- Sys.time()

# Start of Loop
# Load each batch into database
for (i in 2:batches){
  
  # Read rows out of fec.csv according to batch size. Set column names otherwise append will not work
  skipped = (i-1) * max_batchsize + 1
  temp_data <- fread(data_path, nrows = max_batchsize, header = FALSE, skip = skipped)
  names(temp_data) <- column_names
  
  # Write content of tempfile in donation table of fec.sqlite database
  dbWriteTable(fecsqlite, "donations", append = TRUE, header = TRUE, temp_data)
  print(paste0("Batch written: ", i))
  
  #Delete current batch and clean RAM
  rm(temp_data)
  gc()
  
}
# End of Loop

# Measure time after loop terminates
end_time3 <- Sys.time()
time_elapsed3 <- end_time3 - start_time3
print(paste0("Time taken for for writing database: ", round(time_elapsed3, 2), " minutes"))

# Create indeces in "donations" for specific columns we will need in the following exercises
dbExecute(fecsqlite, "CREATE INDEX contributor_category ON donations(contributor_category);")
dbExecute(fecsqlite, "CREATE INDEX transaction_type_donations ON donations(transaction_type);")
dbExecute(fecsqlite, "CREATE INDEX recipient_name ON donations(recipient_name);")
dbExecute(fecsqlite, "CREATE INDEX amount ON donations(amount);")
dbExecute(fecsqlite, "CREATE INDEX seat ON donations(seat);")
dbExecute(fecsqlite, "CREATE INDEX recipient_type ON donations(recipient_type);")
dbExecute(fecsqlite, "CREATE INDEX cycle ON donations(cycle);")

# Create "transactiontypes" table ===================================================================================

# Download table from website and store in data frame transactions
transactions_url <- "https://classic.fec.gov/finance/disclosure/metadata/DataDictionaryTransactionTypeCodes.shtml"
transactions <- transactions_url %>%
  html() %>%
  html_nodes(xpath='//*[@id="fec_mainContent"]/table'[1]) %>%
  html_table(fill = TRUE)
transactions <- transactions[[1]]

# Set column names
colnames(transactions) <- c("Transaction_Types", "Transaction_Types_Description")

# Create table "transactiontypes" and write table to database "fecsqlite"
dbWriteTable(fecsqlite, "transactiontypes", field.types = c(Transaction_Types ="TEXT",
                                                             Transaction_Types_Description = "Text"), overwrite = TRUE, transactions)

# Create indeces in "transactiontypes" for specific columns we will need in the following exercises
dbExecute(fecsqlite, "CREATE INDEX Transaction_Types_Description ON transactiontypes(Transaction_Types_Description);")
dbExecute(fecsqlite, "CREATE INDEX Transaction_Types ON transactiontypes(Transaction_Types);")

#dbReadTable(fecsqlite, "transactiontypes")

# Create "industrycodes" table ====================================================================================

# Download table from website and store in data frame industrycodes 
industrycodes <- read.csv("http://assets.transparencydata.org.s3.amazonaws.com/docs/catcodes.csv")

# Define data.types
industrycodes_dtyps = c(source = "TEXT", code = "TEXT", name = "TEXT", industry = "TEXT", order = "TEXT")

# Create table "industrycodes" and write table to database "fecsqlite"
dbWriteTable(fecsqlite, "industrycodes", field.types = industrycodes_dtyps, overwrite = TRUE, industrycodes)

# Create indeces in "industrycodes" for specific columns we will need in the following exercises
dbExecute(fecsqlite, "CREATE INDEX industry ON industrycodes(industry);")
dbExecute(fecsqlite, "CREATE INDEX code ON industrycodes(code);")

# Show final results ===============================================================================================

# Signal end of computation

# Disconnect with database
dbDisconnect(fecsqlite)

# Drop all existing variables
rm(list = ls())
print("Part I Task 2 completed")
