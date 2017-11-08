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


data_dir <- system.file("shiny/berlin_t/data",
                        package = "aquanes.report")

fst_dir <- file.path(data_dir, "fst")

available_months <- list.dirs(fst_dir,
                              full.names = FALSE)[-1]

n_months <- length(available_months)

if (n_months > 0) {
last_month <- available_months[n_months]

o_path <- list.files(path = file.path(fst_dir, last_month),
                     full.names = TRUE)
t_path <- gsub(sprintf("fst/%s/", last_month), "", o_path, fixed = TRUE)

for (index in seq_along(o_path)) {
print(sprintf("Copy fst data for latest month from %s to %s (is used as default in app!)",
              o_path[index],
              t_path[index]))
file.copy(from = o_path[index],
          to = t_path[index],
          overwrite = FALSE)
}
aquanes.report::load_fst_data(fst_dir = system.file("shiny/berlin_t/data",
package = "aquanes.report"))

} else {
  stop(sprintf("No fst data available under path: %s",
               list.dirs(fst_dir,
                         full.names = TRUE)))
}



} else {

  aquanes.report::load_fst_data(fst_dir = system.file("shiny/berlin_t/data",
                                          package = "aquanes.report"))


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
