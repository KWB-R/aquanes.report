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


  meta_data$Label <- sprintf("%s (%s)",
                             meta_data$ParameterName,
                             meta_data$ParameterUnit)


  df_tidy <- df_tidy %>%
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
#' @param meta_file_path path to metadata file (default:
#' system.file("shiny/berlin_t/data/parameter_site_metadata.csv", package =
#' "aquanes.report")))
#' @return data.frame with imported operational data (analytics data to be added as
#' soon as available)
#' @export
import_data_berlin_t <- function(raw_data_dir = system.file("shiny/berlin_t/data/operation",
                                                            package = "aquanes.report"),
                                 meta_file_path = system.file("shiny/berlin_t/data/parameter_site_metadata.csv",
                                                              package = "aquanes.report")) {


data_berlin_t <- read_pentair_data(raw_data_dir = raw_data_dir,
                                   meta_file_path = meta_file_path)


data_berlin_t$DataType <- "raw"


data_berlin_t$SiteName_ParaName_Unit <- sprintf("%s: %s (%s)",
                                                data_berlin_t$SiteName,
                                                data_berlin_t$ParameterName,
                                                data_berlin_t$ParameterUnit
                                                )


#### To do: joind with ANALYTICS data as soon as available

return(data_berlin_t)
}


