# PREPARATION ================================================================================================

# Install packages. Uncomment commands if needed

#install.packages("data.table")
#install.packages("rvest")
#install.packages("httr")
#install.packages("here")
#install.packages("utils")

# Drop all existing variables
rm(list = ls())

# Load libraries
library(data.table)
library(rvest)
library(httr)
library(utils)
library(here)

# Dynamically set working directory to top folder of project. Do not paste your own wd in here
setwd(here())
getwd()

# ============================================================================================================

# Define basic variables. Names are self-explaining
RAW_URL <- "http://datacommons.s3.amazonaws.com/subsets/td-20140324/contributions.fec.1990.csv.zip"
BASE_URL <- gsub("1990.csv.zip", "", RAW_URL)
OUTPUT_FILE <- "./data/fec.csv"
START_DATE <- 1990
END_DATE <- 2014

# Build URLS and file paths ==================================================================================

# Generate vector containing all resepective years to append to BASE_URL
years <- seq(START_DATE, END_DATE, 2)

# Build final vector of URLs and filepaths
urls <- paste0(BASE_URL, years, ".csv.zip")

# Download each file and store in one large csv file =========================================================

# We could wrap the Sys.time() function around the loop. This way is due to personal preference
start_time <- Sys.time()

for (url in urls){
  
  # Create temporary file
  tmpfile <- tempfile()
  
  # Save data and store in temporary file
  download.file(url, destfile = tmpfile)
  
  # Unzip data
  tmpfile <- unzip(tmpfile)
  
  # Parse data using the fread funtion from the data.table package
  mydata <- fread(tmpfile[1])
  
  # Write parsed file into csv file. Following data will be added thanks to append = TRUE
  fwrite(mydata, file =  OUTPUT_FILE, append = TRUE)
  unlink(tmpfile)
  gc()
  
}

# Measure time for downloading, parsing and adding data to fec.csv file
end_time <- Sys.time()
time_elapsed <- end_time - start_time
print(paste0("Time taken for downloading, parsing and appending the data: ", round(time_elapsed, 2), " minutes"))

# Zip .csv file
zip("./data/fec.csv.zip", files = "./data/fec.csv")

# Inform that Part I Task I is completed
rm(list = ls())
print("Part I Task 1 completed")




