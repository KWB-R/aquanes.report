use_live_data <- FALSE

if (use_live_data) {

library(aquanes.report)
library(dplyr)


  system.time(
    newData_raw_list <- aquanes.report::import_data_berlin_s())


if (newData_raw_list$added_data_points > 0) {
calc_dat <- aquanes.report::calculate_operational_parameters_berlin_s(df = newData_raw_list$df)

siteData_raw_list <- plyr::rbind.fill(newData_raw_list$df,
                                      calc_dat)
rm(newData_raw_list)


compression_rate <- 100 ## maximum compression: 100, no compression: 0

fst::write.fst(x = siteData_raw_list,
               path = "data/siteData_raw_list.fst",
               compress = compression_rate)

print("### Step 4: Performing temporal aggregation ##########################")
system.time(
  siteData_10min_list <- aquanes.report::group_datetime(siteData_raw_list,
                                                        by = 10*60))
fst::write.fst(x = siteData_10min_list,
               path = "data/siteData_10min_list.fst")

system.time(
  siteData_hour_list <- aquanes.report::group_datetime(siteData_raw_list,by = 60*60))

fst::write.fst(x = siteData_hour_list,
               path = "data/siteData_hour_list.fst")

system.time(
  siteData_day_list <- aquanes.report::group_datetime(siteData_raw_list,
                                                      by = "day"))
fst::write.fst(x = siteData_day_list,
               path = "data/siteData_day_list.fst")
}} else {

  siteData_10min_list <- fst::read.fst(path = "data/siteData_10min_list.fst")


}

print("### Step 5: Importing threshold information ##########################")

threshold_file <- system.file("shiny/berlin_s/data/thresholds.csv",
                              package = "aquanes.report")

thresholds <- aquanes.report::get_thresholds(csv_path = threshold_file)

print("### Step 6: Specify available months for reporting ##########################")
report_months <- aquanes.report::create_monthly_selection(startDate = "2017-04-01")

#print("### Step 7: Add default calculated operational parameters ##########################")

report_calc_paras <- "NOT_IMPLEMENTED_YET"
