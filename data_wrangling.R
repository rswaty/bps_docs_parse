

# Header ----
# data wrangling to address issues (on GitHub)
# started Dec 23, 2025
# Randy Swaty
# treating issues one by one, will not load all dependancies at the top


# load packages ----
library(tidyverse)

# Add BpS indicator species to s-class description table ---

# first pivot bps indicator table to wide

bps_indicators_wide <- read_csv("tables/bps_indicators.csv") |>
group_by(bps_model_id) |>
  # assign rank to get number associated with column names (e.g., symbol_1)
  mutate(rank = row_number()) |>
  filter(rank <= 4) |>
  ungroup() |>
  # Pivot wider with numbered columns
  pivot_wider(
    id_cols = bps_model_id,
    names_from = rank,
    values_from = c(symbol, scientific_name, common_name),
    names_glue = "{.value}_{rank}"
  )

# second join to sclass description table

sclass_descriptions <- read_csv('tables/scls_descriptions.csv') |>
  left_join(bps_indicators_wide, by = "bps_model_id")


write.csv(sclass_descriptions, file = "tables/scls_descriptions.csv")




