#' Berlin-Tiefwerder: aggregate and export to fst
#' @param year_month_start start year month (default: '2017-06')
#' @param year_month_end end year month (default: current month)
#' @param compression (default: 100)
#' @return exports data for each month into subfolder: /data/fst/year-month
#' @importFrom data.table rbindlist
#' @importFrom fst write.fst
#' @export
aggregate_export_fst_berlin_t <- function(year_month_start = "2017-06",
                                          year_month_end = format(Sys.Date(), "%Y-%m"),
                                          compression = 100) {
  monthly_periods <- get_monthly_periods(
    year_month_start = year_month_start,
    year_month_end = year_month_end
  )

  for (year_month in monthly_periods$year_month) {
    monthly_period <- monthly_periods[monthly_periods$year_month == year_month, ]

    print(sprintf(
      "Importing data for month '%s':",
      year_month
    ))
    raw_data_file_paths <- get_rawfilespaths_for_month(monthly_period)



    system.time(
      siteData_raw_list <- import_data_berlin_t(
        raw_data_files = raw_data_file_paths
      )
    )


    datetime_start <- as.POSIXct(
      sprintf("%s 00:00:00", monthly_period$start),
      tz = "CET"
    )

    datetime_end <- as.POSIXct(
      sprintf("%s 23:59:59", monthly_period$end),
      tz = "CET"
    )


    condition <- siteData_raw_list$DateTime >= datetime_start &
      siteData_raw_list$DateTime <= datetime_end

    siteData_raw_list <- siteData_raw_list[condition, ]

    print(sprintf(
      "Reduced imported data points to time period: %s - %s",
      as.character(min(siteData_raw_list$DateTime)),
      as.character(max(siteData_raw_list$DateTime))
    ))

    calc_dat <- calculate_operational_parameters_berlin_t(df = siteData_raw_list)

    siteData_raw_list <- data.table::rbindlist(
      l = list(
        siteData_raw_list,
        calc_dat
      ),
      use.names = TRUE,
      fill = TRUE
    ) %>%
      as.data.frame()


    export_dir_path <- sprintf(
      "%s/data/fst/%s",
      system.file(
        "shiny/berlin_t",
        package = "aquanes.report"
      ),
      monthly_period$year_month
    )

    if (!dir.exists(export_dir_path)) {
      print(sprintf("Creating export path: %s", export_dir_path))
      dir.create(export_dir_path, recursive = TRUE)
    }

    system.time(fst::write.fst(
      siteData_raw_list,
      path = sprintf("%s/siteData_raw_list.fst", export_dir_path),
      compress = compression
    ))


    print("### Step 4: Performing temporal aggregation ##########################")
    system.time(
      siteData_10min_list <- group_datetime(
        siteData_raw_list,
        by = 10 * 60
      )
    )
    fst::write.fst(
      siteData_10min_list,
      path = sprintf("%s/siteData_10min_list.fst", export_dir_path),
      compress = compression
    )

    system.time(
      siteData_hour_list <- group_datetime(siteData_10min_list, by = 60 * 60)
    )

    fst::write.fst(
      siteData_hour_list,
      path = sprintf("%s/siteData_hour_list.fst", export_dir_path),
      compress = compression
    )

    system.time(
      siteData_day_list <- group_datetime(
        siteData_hour_list,
        by = "day"
      )
    )
    fst::write.fst(
      siteData_day_list,
      path = sprintf("%s/siteData_day_list.fst", export_dir_path),
      compress = compression
    )
  }
}

#' Berlin-Schoenerlinde: aggregate and export to fst
#' @param year_month_start start year month (default: '2017-04')
#' @param year_month_end end year month (default: current month)
#' @param compression (default: 100)
#' @return exports data for each month into subfolder: /data/fst/year-month
#' @importFrom data.table rbindlist
#' @importFrom fst write.fst
#' @export
aggregate_export_fst_berlin_s <- function(year_month_start = "2017-04",
                                          year_month_end = format(Sys.Date(), "%Y-%m"),
                                          compression = 100) {
  monthly_periods <- get_monthly_periods(
    year_month_start = year_month_start,
    year_month_end = year_month_end
  )

  for (year_month in monthly_periods$year_month) {
    monthly_period <- monthly_periods[monthly_periods$year_month == year_month,]

    print(sprintf(
      "Importing data for month '%s':",
      year_month
    ))
    raw_data_file_paths <- get_monthly_data_from_calendarweeks(year_month = monthly_period$year_month)



    system.time(
      siteData_raw_list <- import_data_berlin_s(
        raw_data_files = raw_data_file_paths
      )
    )


    datetime_start <- as.POSIXct(
      sprintf("%s 00:00:00", monthly_period$start),
      tz = "CET"
    )

    datetime_end <- as.POSIXct(
      sprintf("%s 23:59:59", monthly_period$end),
      tz = "CET"
    )


    condition <- siteData_raw_list$DateTime >= datetime_start &
      siteData_raw_list$DateTime <= datetime_end

    siteData_raw_list <- siteData_raw_list[condition, ]

    print(sprintf(
      "Reduced imported data points to time period: %s - %s",
      as.character(min(siteData_raw_list$DateTime)),
      as.character(max(siteData_raw_list$DateTime))
    ))

    calc_dat <- calculate_operational_parameters_berlin_s(df = siteData_raw_list)

    siteData_raw_list <- data.table::rbindlist(
      l = list(
        siteData_raw_list,
        calc_dat
      ),
      use.names = TRUE,
      fill = TRUE
    ) %>%
      as.data.frame()


    export_dir_path <- sprintf(
      "%s/data/fst/%s",
      system.file(
        "shiny/berlin_s",
        package = "aquanes.report"
      ),
      monthly_period$year_month
    )

    if (!dir.exists(export_dir_path)) {
      print(sprintf("Creating export path: %s", export_dir_path))
      dir.create(export_dir_path, recursive = TRUE)
    }

    system.time(fst::write.fst(
      siteData_raw_list,
      path = sprintf("%s/siteData_raw_list.fst", export_dir_path),
      compress = compression
    ))


    print("### Step 4: Performing temporal aggregation ##########################")
    system.time(
      siteData_10min_list <- group_datetime(
        siteData_raw_list,
        by = 10 * 60
      )
    )
    fst::write.fst(
      siteData_10min_list,
      path = sprintf("%s/siteData_10min_list.fst", export_dir_path),
      compress = compression
    )

    system.time(
      siteData_hour_list <- group_datetime(siteData_10min_list, by = 60 * 60)
    )

    fst::write.fst(
      siteData_hour_list,
      path = sprintf("%s/siteData_hour_list.fst", export_dir_path),
      compress = compression
    )

    system.time(
      siteData_day_list <- group_datetime(
        siteData_hour_list,
        by = "day"
      )
    )
    fst::write.fst(
      siteData_day_list,
      path = sprintf("%s/siteData_day_list.fst", export_dir_path),
      compress = compression
    )
  }
}

