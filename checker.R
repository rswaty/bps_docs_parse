



library(tidyverse)

# refcon
refcon <- read_csv("ReferenceConditionTable14August2020.csv") %>%
  select(Model_Code)

# specify the zone
zone <- "7"

# specify the string pattern for how zone appears in Model_Code
# without trailing zones, e.g. 10800_1
zone_string1 <- paste0("_", zone, "$")
# with trailing zones, e.g. 10800_1_2
zone_string2 <- paste0("_", zone, "_")

## 1) find model_codes in the zone ----
zone_check <- refcon %>%
  mutate(inzone = case_when(
   str_detect(Model_Code, zone_string1) ~ "yes",
   str_detect(Model_Code, zone_string2) ~ "yes",
    .default = "no")
  ) %>%
  filter(inzone == "yes")


## 2) make a list of all file names in the folder ----

path <- paste0("all_bps_docs/mz_zips/", "map_zone_", zone)

files <- 
  # get file names
  tibble(file_name = list.files(path)) %>%
  # remove file extension
  mutate(file_name = str_remove(file_name, "\\.[^.]+$"))

# compare files to refcon
zone_check_names <- zone_check %>%
  mutate(infiles = if_else(
    Model_Code %in% files$file_name, "yes", "no")) %>%
  filter(infiles == "no")


## checking >>> ----
# the number of obs in zone_check should
# match the number obs in files 


## checking >>> ----
# zone_check_names will have 0 records if all the files
# in the zip have a match in the refcon list


## list of checked zones ----
# 1,2,4,5,8,9,10
# 3, 7 OK, it has an extra space in the file name
# 6,  11050 file missing from zip?



