cat("\014") # Clear your console
rm(list = ls()) #clear your environment

########################## Load in header file ######################## #
setwd("~/git/of-dollars-and-data")
source(file.path(paste0(getwd(),"/header.R")))

########################## Load in Libraries ########################## #

library(readxl)
library(dplyr)

########################## Start Program Here ######################### #

# Bring in the data Shiller uses on his website
# Build the data in this step
# Also drop the 2017 data as the dividends are missing
sp500_ret_pe <- read_excel(paste0(importdir, "09-sp500-returns-pe/ie_data.xls"),
                          sheet = "Data") 

colnames(sp500_ret_pe) <- c("date", "price", "div", "earnings", "cpi", "date_frac", 
                            "long_irate", "real_price", "real_div", "real_earn", "cape")

#Remove first 6 rows
sp500_ret_pe <- sp500_ret_pe[7:nrow(sp500_ret_pe),]

# Convert vars to numeric
sp500_ret_pe$real_price <- as.numeric(sp500_ret_pe$real_price)
sp500_ret_pe$real_div <- as.numeric(sp500_ret_pe$real_div)
sp500_ret_pe$date <- as.numeric(sp500_ret_pe$date)
sp500_ret_pe$cpi <- as.numeric(sp500_ret_pe$cpi)
sp500_ret_pe$cape <- as.numeric(sp500_ret_pe$cape)

# Filter out missing dividends
sp500_ret_pe <- sp500_ret_pe %>%
                  filter(!is.na(real_div)) %>%
                  select(date, real_price, real_div, cape, cpi)

# Save down the data
saveRDS(sp500_ret_pe, paste0(localdir, "09-sp500-ret-pe.Rds"))

# ############################  End  ################################## #