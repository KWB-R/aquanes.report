use_live_data <- TRUE

if (use_live_data) {

library(aquanes.report)

year_month_start <- format(Sys.Date() - months(1, abbreviate = FALSE),
                           format = "%Y-%m")
year_month_end <- format(Sys.Date(), format = "%Y-%m")

print("#################################################################################")
print(sprintf(" ###### Generating & exporting .fst files for months: %s - %s",
      year_month_start,
      year_month_end))
print("#################################################################################")

aquanes.report::aggregate_export_fst_berlin_t(year_month_start = year_month_start,
                                              year_month_end = year_month_end)


month_pattern <- paste0(c(year_month_start,year_month_end), collapse = "|")
aquanes.report::merge_and_export_fst(time_pattern = month_pattern)

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
