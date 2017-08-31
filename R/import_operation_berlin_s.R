#'Create WEDECO metafile data
#' @param raw_data_file file path to raw data which should be used for as template
#' for meta file creation
#' @return data.frame with meta data file structure
#' @export
create_wedeco_metafile <- function(raw_data_file) {


  print(paste("Importing raw data file:",raw_data_file ))
  ozone <- read.csv(file = raw_data_file ,
                    header = TRUE,
                    sep = ";",
                    dec = ",",
                    skip = 2,
                    stringsAsFactors = FALSE)


  indices_names <- seq(from = 1,by = 2,to = ncol(ozone) - 1)
  indices_units <- seq(from = 2,by = 2,to = ncol(ozone))

  meta_file <- data.frame(ParameterCode = rep(NA, nrow(ozone)),
                          ParameterName = rep(NA, nrow(ozone)),
                          SiteCode = rep(NA, nrow(ozone)),
                          SiteName = rep(NA, nrow(ozone)),
                          ParameterName_SiteName = names(ozone)[indices_names],
                          ParameterUnitOrg = names(ozone)[indices_units],
                          ParameterUnit = names(ozone)[indices_units]
  )

  return(meta_file)


}


#'Import WEDECO raw data
#' @param raw_data_dir path to raw data directory
#' @param meta_file_path path to meta data file
#' @export
read_wedeco_data <- function(raw_data_dir = system.file("shiny/berlin_s/data/operation",
                                                        package = "aquanes.report"),
                             meta_file_path = system.file("shiny/berlin_s/data/parameter_site_metadata.csv",
                                                          package = "aquanes.report")) {


  files_to_import <- list.files(raw_data_dir,
                                pattern = ".csv",
                                full.names = TRUE)


  for (pathfile in files_to_import) {
    print(paste("Importing raw data file:",pathfile))
    ozone <- read.csv(file = pathfile,
                      header = TRUE,
                      sep = ";",
                      dec = ",",
                      skip = 2,
                      stringsAsFactors = FALSE)


    ozone <- ozone[,c(1,seq(from = 2,by = 2,to = ncol(ozone)))]


    names(ozone)[1] <- "DateTime"



    ozone$DateTime <- as.POSIXct(strptime(ozone$DateTime,
                                          format = "%d.%m.%y %H:%M:%S",
                                          tz = "CET"))


    if (pathfile == files_to_import[1]) {
      df <- ozone
    } else {
      df <- rbind(df, ozone)
    }
  }

  ozone_tidy <- tidyr::gather_(data = df,
                        key_col = "ParameterUnitOrg",
                        value_col = "ParameterValue",
                        gather_cols = setdiff(names(df), "DateTime"))



  meta_data  <- read.csv(file = meta_file_path,
                                      stringsAsFactors = FALSE)

  meta_data$ParameterLabel <- sprintf("%s (%s)",
                             meta_data$ParameterName,
                             meta_data$ParameterUnit)


  df_tidy <- dplyr::left_join(x = ozone_tidy,
                              y = meta_data)


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
#' @param rds_file_path path to rds file (default:
#' system.file("shiny/berlin_s/data/siteData_raw_list.Rds", package =
#' "aquanes.report")))
#' @return data.frame with imported operational data (analytics data to be added as
#' soon as available)
#' @export
import_data_berlin_s <- function(raw_data_dir = system.file("shiny/berlin_s/data/operation",
                                                            package = "aquanes.report"),
                                 meta_file_path = system.file("shiny/berlin_s/data/parameter_site_metadata.csv",
                                                              package = "aquanes.report"),
                                 rds_file_path = system.file("shiny/berlin_s/data/siteData_raw_list.Rds",
                                                              package = "aquanes.report")) {


data_berlin_s <- read_wedeco_data(raw_data_dir = raw_data_dir,
                                   meta_file_path = meta_file_path)


data_berlin_s$DataType <- "raw"


data_berlin_s$SiteName_ParaName_Unit <- sprintf("%s: %s (%s)",
                                                data_berlin_s$SiteName,
                                                data_berlin_s$ParameterName,
                                                data_berlin_s$ParameterUnit
                                                )

if (file.exists(rds_file_path)) {
print(sprintf("Loading already imported data from file: %s", rds_file_path))

old_data <- readRDS(rds_file_path)
new_data <- data_berlin_s[!data_berlin_s$DateTime %in% unique(old_data$DateTime), ]

if (nrow(new_data) > 0) {
print(sprintf("Adding new %d data points for time period: %s - %s",
              nrow(new_data),
              min(new_data$DateTime),
              max(new_data$DateTime)))
data_berlin_s <- rbind(old_data, new_data)
} else {
  cat(sprintf("No additional data points found in files:\n%s",
              paste(list.files(raw_data_dir,
                               pattern = "\\.",
                               full.names = TRUE), collapse = "\n")))
  data_berlin_t <- old_data
}

}


#### To do: joind with ANALYTICS data as soon as available

return(data_berlin_s)
}


