#'BerlinTiefwerder: import lab data
#' @param xlsx_path  full path to lab data EXCEL file in xlsx format (default:
#' (default: system.file("shiny/berlin_t/data/analytics.xlsx",
#' package = "aquanes.report"))))
#' @return a list of imported lab data for Berlin-Tiefwerder
#' @import tidyr
#' @import dplyr
#' @importFrom readxl read_xlsx
#' @importFrom magrittr "%>%"
#' @export
import_lab_data_berlin_t <- function(xlsx_path = system.file("shiny/berlin_t/data/analytics.xlsx",
                                                package = "aquanes.report")) {






  lab_results <- readxl::read_xlsx(path = xlsx_path,
                                   sheet = "Tabelle1",
                                   skip = 12) %>%
    dplyr::mutate_(ParameterName = gsub(pattern ="\\s*\\(.*", "", "ParameterCode"))


  lab_results_list <- lab_results %>%
    tidyr::gather_(key_col = "Combi",
                   value_col = "ParameterValueRaw",
                   gather_cols = setdiff(names(lab_results),
                                         c("ParameterCode",
                                           "ParameterUnit",
                                           "ParameterName"))) %>%
    tidyr::separate_(col = "Combi",
                    into = c("ProbenNr",
                             "Date",
                             "Termin",
                             "Komplexkuerzel",
                             "Ort_Typ",
                             "Art",
                             "Gegenstand",
                             "Bezeichnung",
                             "SiteName",
                             "InterneKN",
                             "Bemerkung",
                             "DateTime"),
                    sep = "@",
                    remove = TRUE)  %>%
    dplyr::mutate_(Date = "as.numeric(Date)") %>%
    dplyr::mutate_(Date = "janitor::excel_numeric_to_date(date_num = Date,
                                                        date_system = 'modern')") %>%
    dplyr::mutate_(Termin = "as.numeric(Termin)") %>%
    dplyr::mutate_(Termin = "janitor::excel_numeric_to_date(date_num = Termin,
                                                          date_system = 'modern')") %>%
    dplyr::mutate_(DateTime = "gsub(',', '.', DateTime)") %>%
    dplyr::mutate_(DateTime = "as.POSIXct(as.numeric(DateTime)*24*3600,
                                        origin = '1899-12-30',
                                        tz = 'CET')") %>%
    dplyr::mutate_(ParameterValue = "gsub(',', '.', ParameterValueRaw)",
                  DetectionLimit = "ifelse(test = grepl('<', ParameterValue),
                                          yes = 'below',
                                          no = 'above')") %>%
    dplyr::mutate_(DetectionLimit_numeric = "ifelse(test = grepl('<', ParameterValue),
                                                    yes = as.numeric(gsub('<', '', ParameterValue)),
                                                    no = NA)",
                  ParameterValue = "ifelse(test = grepl('<', ParameterValue),
                                          yes = as.numeric(gsub('<', '', ParameterValue))/2,
                                          no = as.numeric(ParameterValue))")


  site_names <- unique(lab_results_list$SiteName)

  site_meta <- data.frame(SiteCode = seq_along(site_names),
                          SiteName = site_names,
                          stringsAsFactors = FALSE)

  lab_results_list <- lab_results_list %>%
                      dplyr::left_join(site_meta) %>%
                      dplyr::mutate(Source = "offline")



  res <- list(matrix = lab_results,
              list = lab_results_list)

  return(res)
}


#'Read PENTAIR operational data
#' @param raw_data_dir path of directory containing PENTAIR xls files (default:
#' (default: system.file("shiny/berlin_t/data/operation",
#' package = "aquanes.report"))))
#' @param meta_file_path path to metadata file (default:
#' system.file("shiny/berlin_t/data/parameter_site_metadata.csv", package =
#' "aquanes.report")))
#' @return data.frame with imported PENTAIR operational data
#' @import tidyr
#' @importFrom readr read_tsv
#' @importFrom magrittr "%>%"
#' @export
read_pentair_data <- function(raw_data_dir = system.file("shiny/berlin_t/data/operation",
                                                         package = "aquanes.report"),
                              meta_file_path = system.file("shiny/berlin_t/data/parameter_site_metadata.csv",
                                                           package = "aquanes.report")) {

  xls_files <- list.files(path = raw_data_dir,
                          pattern = "*.xls",
                          full.names = TRUE)


  for (xls_file in xls_files) {
    print(paste("Importing raw data file:", xls_file))
    tmp <- readr::read_tsv(file = xls_file,
                           locale = readr::locale(tz = "CET"))



    if (xls_file == xls_files[1]) {
      df <- tmp
    }  else {
      df <- rbind(df, tmp)
    }
  }
  df_tidy <- tidyr::gather_(data = df,
                            key_col = "ParameterCode",
                            value_col = "ParameterValue",
                            gather_cols = setdiff(names(df), "TimeStamp")) %>%
             dplyr::rename_(DateTime = "TimeStamp")


  meta_data <- read.csv(file = meta_file_path,
                        header = TRUE,
                        sep = ",",
                        dec = ".",
                        stringsAsFactors = FALSE)


  meta_data$ParameterLabel <- sprintf("%s (%s)",
                             meta_data$ParameterName,
                             meta_data$ParameterUnit)


  relevant_paras <- df_tidy$ParameterCode %in% meta_data$ParameterCode[meta_data$ZeroOne == 1]

  meta_data <- meta_data %>%
    select_(.dots = "-ZeroOne")


  df_tidy <- df_tidy[relevant_paras,] %>%
    dplyr::left_join(y = meta_data) %>%
    as.data.frame()

  df_tidy$Source <- "online"

  no_sitenames <- is.na(df_tidy$SiteName)

  df_tidy$SiteName[no_sitenames] <- "General"

  return(df_tidy)
}

#' Import data for Berlin Tiefwerder
#' @param raw_data_dir path of directory containing PENTAIR xls files (default:
#' (default: system.file("shiny/berlin_t/data/operation",
#' package = "aquanes.report"))))
#' @param analytics_path  full path to lab data EXCEL file in xlsx format (default:
#' (default: system.file("shiny/berlin_t/data/analytics.xlsx",
#' package = "aquanes.report"))))
#' @param meta_file_path path to metadata file (default:
#' system.file("shiny/berlin_t/data/parameter_site_metadata.csv", package =
#' "aquanes.report")))
#' @param fst_file_path path to fst file (default:
#' system.file("shiny/berlin_t/data/siteData_raw_list.fst", package =
#' "aquanes.report")))
#' @return list with "df": data.frame with imported operational data (analytics
#' data to be added as soon as available) and "added_data_points": number of
#' added data points in case of existing fst file was updated with new operational
#' data
#' @export
import_data_berlin_t <- function(raw_data_dir = system.file("shiny/berlin_t/data/operation",
                                                            package = "aquanes.report"),
                                 analytics_path = system.file("shiny/berlin_t/data/analytics.xlsx",
                                                             package = "aquanes.report"),
                                 meta_file_path = system.file("shiny/berlin_t/data/parameter_site_metadata.csv",
                                                              package = "aquanes.report"),
                                 fst_file_path = system.file("shiny/berlin_t/data/siteData_raw_list.fst",
                                                             package = "aquanes.report")) {


data_berlin_t <- read_pentair_data(raw_data_dir = raw_data_dir,
                                   meta_file_path = meta_file_path)

#### To do: joind with ANALYTICS data as soon as available
# data_berlin_t_offline <- read_pentair_data(raw_data_dir = raw_data_dir,
#                                    meta_file_path = meta_file_path)

# data_berlin_t_offline <- import_lab_data_berlin_t(raw_data_dir = raw_data_dir,
#                                           meta_file_path = meta_file_path)


data_berlin_t$DataType <- "raw"


data_berlin_t$SiteName_ParaName_Unit <- sprintf("%s: %s (%s)",
                                                data_berlin_t$SiteName,
                                                data_berlin_t$ParameterName,
                                                data_berlin_t$ParameterUnit
                                                )




if (file.exists(fst_file_path)) {
  print(sprintf("Loading already imported data from file: %s", fst_file_path))

  old_data <- aquanes.report::read_fst(fst_file_path)
  new_data <- data_berlin_t[!data_berlin_t$DateTime %in% unique(old_data$DateTime), ]

  added_data_points <- nrow(new_data)

  if (added_data_points > 0) {

    print(sprintf("Adding new %d data points for time period: %s - %s",
                  added_data_points,
                  min(new_data$DateTime),
                  max(new_data$DateTime)))
    data_berlin_t <- rbind(old_data, new_data)
  } else {
    cat(sprintf("No additional data points found in files:\n%s",
                  paste(list.files(raw_data_dir,
                                   pattern = "\\.",
                                   full.names = TRUE), collapse = "\n")))
    data_berlin_t <- old_data
  }
}  else {
  added_data_points <- nrow(data_berlin_t)
  print(sprintf("First import (no existing '.fst' file): adding new %d data points for time period: %s - %s",
                added_data_points,
                min(data_berlin_t$DateTime),
                max(data_berlin_t$DateTime)))
}

### Remove duplicates if any exist
data_berlin_t <- remove_duplicates(df = data_berlin_t,
                                   col_names = c("DateTime", "ParameterCode", "SiteCode"))




return(list(df = data_berlin_t,
            added_data_points = added_data_points))
}


