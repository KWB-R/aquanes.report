use_live_data <- FALSE

if (use_live_data) {

library(aquanes.report)
library(dplyr)


metadata <- read.csv(file = "data/parameter_site_metadata.csv",
                     stringsAsFactors = FALSE) %>%
    dplyr::filter(ZeroOne == 1) %>%
    dplyr::select("ParameterName_SiteName", "ZeroOne") %>%
    as.data.frame()

  system.time(
    newData_raw_list <- aquanes.report::import_data_berlin_s() %>%
      dplyr::filter(ParameterName_SiteName %in% metadata$ParameterName_SiteName))

if (newData_raw_list$added_data_points > 0) {
calc_dat <- aquanes.report::calculate_operational_parameters_berlin_s(df = newData_raw_list$df)

newData_raw_list$df <- plyr::rbind.fill(newData_raw_list$df,
                                      calc_dat)




print("### Step 4: Performing temporal aggregation ##########################")
system.time(
newData_10min_list <- aquanes.report::group_datetime(newData_raw_list$df,
                                                      by = 10*60))

system.time(
newData_hour_list <- aquanes.report::group_datetime(newData_raw_list$df,
                                                     by = 60*60))

system.time(
  newData_day_list <- aquanes.report::group_datetime(newData_raw_list$df,
                                                        by = "day"))


saveRDS(newData_raw_list, file = "data/siteData_raw_list.Rds")
saveRDS(newData_10min_list, file = "data/siteData_10min_list.Rds")
saveRDS(newData_hour_list, file = "data/siteData_hour_list.Rds")
saveRDS(newData_day_list, file = "data/siteData_day_list.Rds")
}
} 

#siteData_raw_list <- readRDS("data/siteData_raw_list.Rds")
siteData_10min_list <- readRDS("data/siteData_10min_list.Rds")
#siteData_hour_list <- readRDS("data/siteData_hour_list.Rds")
#siteData_day_list <- readRDS("data/siteData_day_list.Rds")


print("### Step 5: Importing threshold information ##########################")

threshold_file <- system.file("shiny/berlin_s/data/thresholds.csv",
                              package = "aquanes.report")

thresholds <- aquanes.report::get_thresholds(csv_path = threshold_file)

print("### Step 6: Specify available months for reporting ##########################")
report_months <- aquanes.report::create_monthly_selection(startDate = "2017-04-01")

#print("### Step 7: Add default calculated operational parameters ##########################")

report_calc_paras <- "NOT_IMPLEMENTED_YET"
