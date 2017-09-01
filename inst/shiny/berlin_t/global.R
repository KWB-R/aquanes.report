use_live_data <- TRUE

if (use_live_data) {

library(aquanes.report)

system.time(
newData_raw_list <- aquanes.report::import_data_berlin_t())

if (newData_raw_list$added_data_points > 0) {
siteData_raw_list <- newData_raw_list$df
rm(newData_raw_list)
print("### Step 4: Performing temporal aggregation ##########################")
system.time(
siteData_10min_list <- aquanes.report::group_datetime(siteData_raw_list,
                                                      by = 10*60))

system.time(
siteData_hour_list <- aquanes.report::group_datetime(siteData_raw_list,
                                                     by = 60*60))

system.time(
  siteData_day_list <- aquanes.report::group_datetime(siteData_raw_list,
                                                        by = "day"))



compression_rate <- 100 ## maximum compression: 100, no compression: 0

fst::write.fst(x = siteData_raw_list,
               path = "data/siteData_raw_list.fst",
               compress = compression_rate)

fst::write.fst(x = siteData_10min_list,
        path = "data/siteData_10min_list.fst")
fst::write.fst(x = siteData_hour_list,
        path = "data/siteData_hour_list.fst")
fst::write.fst(x = siteData_day_list,
        path = "data/siteData_day_list.fst")
}
} else {

  siteData_10min_list <- fst::read.fst(path = "data/siteData_10min_list.fst")


}

print("### Step 5: Importing threshold information ##########################")

threshold_file <- system.file("shiny/berlin_t/data/thresholds.csv",
                              package = "aquanes.report")

thresholds <- aquanes.report::get_thresholds(csv_path = threshold_file)

print("### Step 6: Specify available months for reporting ##########################")
report_months <- aquanes.report::create_monthly_selection(startDate = "2017-06-01")

#print("### Step 7: Add default calculated operational parameters ##########################")

#report_calc_paras <- unique(aquanes.report::calculate_operational_parameters(df = siteData_10min_list)$ParameterName)

report_calc_paras <- "NOT_IMPLEMENTED_YET"
