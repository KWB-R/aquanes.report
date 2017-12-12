#' Create WEDECO metafile data
#' @param raw_data_file file path to raw data which should be used for as template
#' for meta file creation
#' @return data.frame with meta data file structure
#' @importFrom data.table fread
#' @importFrom tidyr separate
#' @export
create_wedeco_metafile <- function(raw_data_file) {
  print(paste("Importing raw data file:", raw_data_file))
  ozone <- data.table::fread(
    input = raw_data_file,
    header = TRUE,
    sep = ";",
    skip = 2
  )


  indices_names <- seq(from = 1, by = 2, to = ncol(ozone) - 1)
  indices_units <- seq(from = 2, by = 2, to = ncol(ozone))

  meta_file <- data.frame(
    ParameterCode = rep(NA, length(indices_names)),
    ParameterName = rep(NA, length(indices_names)),
    SiteCode = rep(NA, length(indices_names)),
    SiteName = rep(NA, length(indices_names)),
    ParameterName_SiteName = names(ozone)[indices_names],
    ParameterUnitOrg = names(ozone)[indices_units],
    ParameterUnit = names(ozone)[indices_units],
    stringsAsFactors = FALSE
  ) %>%
    tidyr::separate(
      col = "ParameterName_SiteName",
      into = c(
        "ProzessSignal",
        "ProzessID",
        "ProzessName"
      ),
      sep = " - ",
      remove = FALSE
    )

  meta_file$ProzessID <- as.numeric(meta_file$ProzessID)

  meta_file$ParameterUnit <- sub(
    pattern = "_",
    replacement = "/",
    x = meta_file$ParameterUnit
  )

  meta_file$ParameterUnit <- sub(
    pattern = "V.*",
    replacement = "",
    x = meta_file$ParameterUnit
  )



  return(meta_file)
}


#' Import WEDECO raw data
#' @param raw_data_dir path to raw data directory
#' @param meta_file_path path to meta data file
#' @importFrom lubridate parse_date_time2
#' @importFrom stringr str_sub
#' @importFrom plyr rbind.fill
#' @export
read_wedeco_data <- function(raw_data_dir = system.file(
                             "shiny/berlin_s/data/operation",
                             package = "aquanes.report"
                           ),
                           meta_file_path = system.file(
                             "shiny/berlin_s/data/parameter_site_metadata.csv",
                             package = "aquanes.report"
                           )) {
  files_to_import <- list.files(
    raw_data_dir,
    pattern = ".csv",
    full.names = TRUE
  )


  for (pathfile in files_to_import) {
    print(paste("Importing raw data file:", pathfile))
    ozone <- data.table::fread(
      input = pathfile,
      header = TRUE,
      sep = ";",
      dec = ",",
      skip = 2
    )

    indices_names <- seq(from = 1, by = 2, to = ncol(ozone) - 1)
    indices_units <- seq(from = 2, by = 2, to = ncol(ozone))


    process_ids <- stringr::str_sub(names(ozone)[indices_names], 6, 11)

    names(ozone)[indices_units] <- process_ids

    ozone <- ozone[, c(1, indices_units), with = FALSE]


    names(ozone)[1] <- "DateTime"


    ozone$DateTime <- lubridate::parse_date_time2(
      ozone$DateTime,
      orders = "d!.m!*.y!* H!:M!:S!",
      tz = "CET"
    )


    if (pathfile == files_to_import[1]) {
      df <- ozone
    } else {
      df <- plyr::rbind.fill(df, ozone)
    }
  }

  df_tidy <- tidyr::gather_(
    data = df,
    key_col = "ProzessID",
    value_col = "ParameterValue",
    gather_cols = setdiff(names(df), "DateTime")
  ) %>%
    dplyr::mutate_(ProzessID = "as.numeric(ProzessID)")



  meta_data <- read.csv(
    file = meta_file_path,
    stringsAsFactors = FALSE
  ) %>%
    dplyr::select_(
      "ProzessID",
      "ParameterCode",
      "ParameterName",
      "ParameterUnit",
      "SiteCode",
      "SiteName",
      "ZeroOne"
    )

  meta_data$ParameterLabel <- sprintf(
    "%s (%s)",
    meta_data$ParameterName,
    meta_data$ParameterUnit
  )

  relevant_paras <- df_tidy$ProzessID %in% meta_data$ProzessID[meta_data$ZeroOne == 1]


  meta_data <- meta_data %>%
    select_(.dots = "-ZeroOne")

  df_tidy <- df_tidy[relevant_paras, ] %>%
    dplyr::left_join(y = meta_data) %>%
    as.data.frame()




  df_tidy$Source <- "online"

  no_sitenames <- is.na(df_tidy$SiteName) | df_tidy$SiteName == ""

  df_tidy$SiteName[no_sitenames] <- "General"


  return(df_tidy)
}

#' Import data for Berlin Schoenerlinde
#' @param raw_data_dir path of directory containing WEDECO CSV files (default:
#' (default: system.file("shiny/berlin_s/data/operation",
#' package = "aquanes.report"))))
#' @param meta_file_path path to metadata file (default:
#' system.file("shiny/berlin_s/data/parameter_site_metadata.csv", package =
#' "aquanes.report")))
#' @param fst_file_path path to fst file (default:
#' system.file("shiny/berlin_s/data/siteData_raw_list.fst", package =
#' "aquanes.report")))
#' @return list with "df": data.frame with imported operational data (analytics
#' data to be added as soon as available) and "added_data_points": number of
#' added data points in case of existing fst file was updated with new operational
#' data
#' @export
import_data_berlin_s <- function(raw_data_dir = system.file(
                                 "shiny/berlin_s/data/operation",
                                 package = "aquanes.report"
                               ),
                               meta_file_path = system.file(
                                 "shiny/berlin_s/data/parameter_site_metadata.csv",
                                 package = "aquanes.report"
                               ),
                               fst_file_path = system.file(
                                 "shiny/berlin_s/data/siteData_raw_list.fst",
                                 package = "aquanes.report"
                               )) {
  data_berlin_s <- read_wedeco_data(
    raw_data_dir = raw_data_dir,
    meta_file_path = meta_file_path
  )


  data_berlin_s$DataType <- "raw"


  data_berlin_s$SiteName_ParaName_Unit <- sprintf(
    "%s: %s (%s)",
    data_berlin_s$SiteName,
    data_berlin_s$ParameterName,
    data_berlin_s$ParameterUnit
  )


  if (file.exists(fst_file_path)) {
    print(sprintf("Loading already imported data from file: %s", fst_file_path))

    old_data <- aquanes.report::read_fst(fst_file_path)
    new_data <- data_berlin_s[!data_berlin_s$DateTime %in% unique(old_data$DateTime), ]

    added_data_points <- nrow(new_data)

    if (added_data_points > 0) {
      print(sprintf(
        "Adding new %d data points for time period: %s - %s",
        added_data_points,
        min(new_data$DateTime),
        max(new_data$DateTime)
      ))
      data_berlin_s <- rbind(old_data, new_data)
    } else {
      cat(sprintf(
        "No additional data points found in files:\n%s",
        paste(list.files(
          raw_data_dir,
          pattern = "\\.",
          full.names = TRUE
        ), collapse = "\n")
      ))
      data_berlin_s <- old_data
    }
  } else {
    added_data_points <- nrow(data_berlin_s)
    print(sprintf(
      "First import (no existing '.fst' file): adding new %d data points for time period: %s - %s",
      added_data_points,
      min(data_berlin_s$DateTime),
      max(data_berlin_s$DateTime)
    ))
  }


  #### To do: joind with ANALYTICS data as soon as available

  return(list(
    df = data_berlin_s,
    added_data_points = added_data_points
  ))
}
