cat("\014") # Clear your console
rm(list = ls()) #clear your environment

########################## Load in header file ######################## #
setwd("~/git/of-dollars-and-data")
source(file.path(paste0(getwd(),"/header.R")))

########################## Load in Libraries ########################## #

library(dplyr)
library(ggplot2)
library(tidyr)
library(scales)
library(grid)
library(gridExtra)
library(gtable)
library(RColorBrewer)
library(stringr)
library(ggrepel)

########################## Start Program Here ######################### #

# Load data fom local library
bls_cx <- readRDS(paste0(localdir, "08-bls-cx.Rds"))

read_in <- function(string){
  temp <- readRDS(paste0(localdir, "08-bls-cx-", string, ".Rds"))
  return(temp)
}

names <- c("item", "demographics", "characteristics", "subcategory", "category")

# Loop through datasets to read in
for (i in names){
  tmpname <- paste0(i)
  df      <- read_in(i)
  assign(tmpname, df, envir = .GlobalEnv)
  rm(df)
  rm(tmpname)
}

#Add an item list
item_list <- c("Food", "Housing", "Transportation", "Healthcare")

# Filter main cx data
bls_cx_expenditures <- filter(bls_cx, 
                          category_name == "Expenditures",
                          characteristics_name != "Total complete income reporters",
                          characteristics_name != "Incomplete income reports",
                          item_name %in% item_list)

bls_cx_income <- filter(bls_cx, subcategory_name == "Income after taxes") %>%
  mutate(income = value) %>%
  select(year, demographics_name, characteristics_name, income)

bls_cx_expenditures <-  bls_cx_expenditures %>%
  inner_join(bls_cx_income)      %>%
  mutate(share = value / income)

# Create a list for looping
loop_list <- unique(select(bls_cx_expenditures, item_name, demographics_name))

for (i in 1:nrow(loop_list)){
  to_plot              <- filter(bls_cx_expenditures, item_name == loop_list[i, 1], 
                                 demographics_name == loop_list[i, 2])
  last_year            <- max(to_plot$year)
  item_code            <- unique(to_plot$item_code)
  demographics_code    <- unique(to_plot$demographics_code)
  
  # Set the file_path 
  file_path = paste0(exportdir, "08-bls-consumer-expenditures/", item_code, "-", demographics_code, ".jpeg")
  
  # Plot the time trends
  plot <- ggplot(to_plot, aes(x = year, y = share, col = characteristics_name))  +
    geom_line() +
    geom_text_repel(data = filter(to_plot, year == last_year),
                    aes(year, 
                        share, 
                        label = characteristics_name, 
                        family = "my_font"), 
                    size = 3)+
    scale_color_discrete(guide=FALSE) +
    scale_y_continuous(label = percent) +
    ggtitle(paste0(loop_list[i, 1], "\n", loop_list[i, 2]))  +
    of_dollars_and_data_theme +
    labs(x = "Year" , y = "Annual Share")
  
  # Turn plot into a gtable for adding text grobs
  my_gtable   <- ggplot_gtable(ggplot_build(plot))
  
  source_string <- "Source:  Bureau of Labor Statistics, Consumer Expenditures (OfDollarsAndData.com)"
  note_string   <- "Note:  " 
  
  # Make the source and note text grobs
  source_grob <- textGrob(source_string, x = (unit(0.5, "strwidth", source_string) + unit(0.2, "inches")), y = unit(0.1, "inches"),
                          gp =gpar(fontfamily = "my_font", fontsize = 8))
  note_grob   <- textGrob(note_string, x = (unit(0.5, "strwidth", note_string) + unit(0.2, "inches")), y = unit(0.15, "inches"),
                          gp =gpar(fontfamily = "my_font", fontsize = 8))
  
  # Add the text grobs to the bototm of the gtable
  my_gtable   <- arrangeGrob(my_gtable, bottom = source_grob)
  my_gtable   <- arrangeGrob(my_gtable, bottom = note_grob)
  
  # Save the plot  
  ggsave(file_path, my_gtable, width = 15, height = 12, units = "cm") 
}


# ############################  End  ################################## #