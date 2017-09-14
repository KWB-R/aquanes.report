#'Imports operational data for Basel (without metadata and only for one site
#'at once, e.g. "rhein" or "wiese")
#' @param xlsx_dir Define directory with raw data in EXCEL spreadsheet (.xlsx) to
#' be imported (default: system.file("shiny/basel/data/operation/wiese",
#' package = "aquanes.report"))
#' @return returns data frame with imported raw operational data
#' @importFrom  readxl read_excel
#' @importFrom  tidyr gather_
#' @export

import_operation_basel <- function(xlsx_dir = system.file("shiny/basel/data/operation/wiese",
                                                                package = "aquanes.report")) {


  xlsx_files <- list.files(path = xlsx_dir,
                           pattern = "\\.xls",
                           full.names = TRUE)


  for (xlsx_file in xlsx_files) {
    print(sprintf("Importing: %s", xlsx_file))
    tmp <- readxl::read_excel(path = xlsx_file)

    if (xlsx_file == xlsx_files[1]) {
      raw_data <- tmp
    } else {
      raw_data <- rbind(raw_data, tmp)
    }
  }

  names(raw_data)[1] <- "DateTime"

  print(sprintf("Setting time zone to 'CET'"))
  raw_data <- aquanes.report::set_timezone(raw_data,tz = "CET")

  raw_data_tidy <- tidyr::gather_(data = raw_data,
                                  key_col = "Parameter_Site_Unit",
                                  value_col = "ParameterValue",
                                  gather_cols = setdiff(names(raw_data), "DateTime"))


  raw_data_tidy$Source <- "online"
  raw_data_tidy$DataType <- "raw"

  return(raw_data_tidy )
}


#'Imports analytical data for Basel (without metadata)
#' @param csv_dir Define directory with raw analytical data in CSV (.csv) format to
#' be imported (default: system.file("shiny/basel/data/analytics",
#' package = "aquanes.report"))
#' @return returns data frame with imported raw analytics data
#' @importFrom janitor clean_names
#' @importFrom  readxl read_excel
#' @importFrom  utils read.csv2
#' @import dplyr
#' @export


import_analytics_basel <- function(csv_dir = system.file("shiny/basel/data/analytics",
                                                        package = "aquanes.report")) {


  csv_files <- list.files(path = csv_dir,
                          pattern = "\\.csv",
                          full.names = TRUE)


  for (csv_file in csv_files) {
    print(sprintf("Importing: %s", csv_file))
    tmp <- read.csv2(file = csv_file,
                     na.strings = "",
                     stringsAsFactors = FALSE)  %>%
      janitor::clean_names()

    tmp <-  tmp %>%
      dplyr::mutate(DateTime = as.POSIXct(strptime(x = paste(tmp$datum,
                                                             tmp$uhrzeit),
                                                   format = "%d.%m.%Y %H:%M"))) %>%
      dplyr::rename(SiteCode = "probestelle",
                    ParameterCode = "pr\u00FCfpunkt",
                    ParameterOperator = "operator",
                    ParameterValue = "messwert",
                    ParameterUnitOrg = "einheit"
      ) %>%
      dplyr::select("DateTime",
                    "SiteCode",
                    "ParameterCode",
                    "ParameterOperator",
                    "ParameterValue",
                    "ParameterUnitOrg")



    if (csv_file == csv_files[1]) {
      raw_data <- tmp
    } else {
      raw_data <- rbind(raw_data, tmp)
    }
  }

  print(sprintf("Setting time zone to 'CET'"))
  raw_data <- aquanes.report::set_timezone(raw_data,tz = "CET")

  raw_data$ParameterValue <- as.numeric(raw_data$ParameterValue)
  raw_data$Source <- "offline"
  raw_data$DataType <- "raw"

  return(raw_data)
}


#'Helper function: add site metadata
#' @param df data frame containing at least a column "SiteCode"
#' @param df_col_sitecode column in df containing site code (default: "SiteCode")
#' @param meta_site_path Define path of "meta_site.csv" to be imported
#' (default: system.file("shiny/basel/data/metadata/meta_site.csv",
#' package = "aquanes.report"))
#' @return returns input data frame with joined metadata
#' @importFrom  tidyr separate_
#' @export

add_site_metadata <- function(df,
                              df_col_sitecode = "SiteCode",
                              meta_site_path = system.file("shiny/basel/data/metadata/meta_site.csv",
                                          package = "aquanes.report")) {

  meta_site <- read.csv(file = meta_site_path ,
                       stringsAsFactors = FALSE)

  res <- df %>%
    tidyr::separate_(col = df_col_sitecode,
                     sep = "-",
                     into = paste0("SiteName", 1:3),
                     remove = FALSE)


  for (siteID in 1:3) {
    print(sprintf("Replacing SiteCode%d with SiteName%d",
                  siteID,
                  siteID))
    col_sitename <- paste0("SiteName", siteID)
    sites <- meta_site[meta_site$SiteID == siteID,]

    if (nrow(sites) > 0) {
      for (site_idx in 1:nrow(sites)) {
        sel_site <- sites[site_idx,]
        strings_to_replace <- !is.na(res[,col_sitename]) & res[,col_sitename] == sel_site$SiteLocation
        if (sum(strings_to_replace) > 0) {
          res[strings_to_replace,col_sitename] <- sel_site$SiteLocationName
        }
      }
    }
    res[is.na(res[,col_sitename]), col_sitename] <- ""
  }

  res$SiteName <- sprintf("%s (%s %s)",
                          res$SiteName1,
                          res$SiteName2,
                          res$SiteName3)

  return(res)
}


#'Helper function: add parameter metadata
#' @param df data frame containing at least a column "ParameterCode"
#' @param meta_parameter_path Define path of "meta_parameter.csv" to be imported
#' (default: system.file("shiny/basel/data/metadata/meta_parameter.csv",
#' package = "aquanes.report"))
#' @return returns input data frame with joined metadata
#' @importFrom  dplyr left_join
#' @export
add_parameter_metadata <- function(df,
                                   meta_parameter_path = system.file("shiny/basel/data/metadata/meta_parameter.csv",
                                                                     package = "aquanes.report")) {


  meta_parameter <- read.csv(file = meta_parameter_path,
                            stringsAsFactors = FALSE)


  res <- df %>%
         dplyr::left_join(meta_parameter)

return(res)
}

#'Helper function: add label ("SiteName_ParaName_Unit")
#' @param df data frame containing at least a columns "SiteName", "ParameterName",
#' "ParameterUnit"
#' @param col_sitename column in df containing site name (default: "SiteName")
#' @param col_parametername column in df containing parameter name (default: "ParameterName")
#' @param col_parameterunit column in df containing parameter unit (default: "ParameterUnit")
#' @return returns input data frame with added column "SiteName_ParaName_Unit"
#' @export

add_label <- function(df,
                      col_sitename = "SiteName",
                      col_parametername = "ParameterName",
                      col_parameterunit = "ParameterUnit") {


  df$SiteName_ParaName_Unit <- sprintf("%s: %s (%s)",
                                       df[,col_sitename],
                                       df[,col_parametername],
                                       df[,col_parameterunit])

  return(df)

}



#'Imports operational data for Basel (with metadata for
#'both sites at once, i.e. "rhein" and "wiese")
#' @param raw_dir_rhein Define directory for site "rhein" with raw data in
#' EXCEL spreadsheet format (.xlsx) to be imported (default:
#' system.file("shiny/basel/data/operation/rhein", package = "aquanes.report"))
#' @param raw_dir_wiese Define directory for site "rhein" with raw data in
#' EXCEL spreadsheet format (.xlsx) to be imported (default:
#' system.file("shiny/basel/data/operation/wiese", package = "aquanes.report"))
#' @param meta_online_path path to file containing metadata for online data
#' (default: system.file("shiny/basel/data/metadata/meta_online.csv",
#' package = "aquanes.report"))
#' @param meta_site_path Define path of "meta_site.csv" to be imported
#' (default: system.file("shiny/basel/data/metadata/meta_site.csv",
#' package = "aquanes.report"))
#' @param meta_parameter_path Define path of "meta_parameter.csv" to be imported
#' (default: system.file("shiny/basel/data/metadata/meta_parameter.csv",
#' package = "aquanes.report"))
#' @return returns data frame with imported raw operational data with metadata
#' for both sites (i.e."rhein" and "wiese")
#' @importFrom  dplyr left_join
#' @return data.frame with operational data for Basel sites including metadata
#' @export
import_operation_meta_basel <- function(
raw_dir_rhein = system.file(file.path("shiny",
"basel/data/operation/rhein"),package = "aquanes.report"),
raw_dir_wiese = system.file("shiny/basel/data/operation/wiese",
            package = "aquanes.report"),
meta_online_path =
system.file("shiny/basel/data/metadata/meta_online.csv",
            package = "aquanes.report"),
meta_site_path =
system.file("shiny/basel/data/metadata/meta_site.csv",
            package = "aquanes.report"),
meta_parameter_path =
  system.file("shiny/basel/data/metadata/meta_parameter.csv",
              package = "aquanes.report")) {



meta_online <- read.csv(file = meta_online_path,
                        stringsAsFactors = FALSE)


online_meta <- add_site_metadata(df = meta_online,
                                 meta_site_path = meta_site_path) %>%
  add_parameter_metadata(meta_parameter_path = meta_parameter_path) %>%
  add_label()

### 1.1) Wiese: Import XLSX data and join with metadata
print("###################################################################")
print("######## Importing operational data with metadata for site 'Wiese'")
print("###################################################################")

wiese <- import_operation_basel(xlsx_dir = raw_dir_wiese) %>%
  dplyr::left_join(online_meta[grep(pattern = "WF",
                                    online_meta$SiteCode),])


### 1.2) Rhein: Import XLSX data and join with metadata
print("###################################################################")
print("######## Importing operational data with metadata for site 'Rhein'")
print("###################################################################")

rhein <- import_operation_basel(xlsx_dir = raw_dir_rhein) %>%
  dplyr::left_join(online_meta[grep(pattern = "RF",
                                    online_meta$SiteCode),])

basel <- rbind(wiese, rhein)

return(basel)
}

#'Imports analytical data for Basel (with metadata for both sites at once, i.e.
#'"rhein" and "wiese")
#' @param analytics_dir Define directory with raw analytical data in CSV (.csv) format to
#' be imported (default: system.file("shiny/basel/data/analytics",
#' package = "aquanes.report"))
#' @param meta_site_path Define path of "meta_site.csv" to be imported
#' (default: system.file("shiny/basel/data/metadata/meta_site.csv",
#' package = "aquanes.report"))
#' @param meta_parameter_path Define path of "meta_parameter.csv" to be imported
#' (default: system.file("shiny/basel/data/metadata/meta_parameter.csv",
#' package = "aquanes.report"))
#' @return data.frame with analytics data for Basel sites including metadata
#' @export
import_analytics_meta_basel <- function(
analytics_dir = system.file("shiny/basel/data/analytics",
                            package = "aquanes.report"),
meta_site_path = system.file("shiny/basel/data/metadata/meta_site.csv",
package = "aquanes.report"),
meta_parameter_path = system.file("shiny/basel/data/metadata/meta_parameter.csv",
package = "aquanes.report")) {

print("###################################################################")
print("###### Importing analytics data with metadata for sites 'Wiese' and Rhein'")
print("###################################################################")

analytics_meta_data <- import_analytics_basel(csv_dir = analytics_dir) %>%
  add_site_metadata(meta_site_path = meta_site_path) %>%
  add_parameter_metadata(meta_parameter_path = meta_parameter_path) %>%
  add_label()

return(analytics_meta_data )
}

#'Imports operational & analytical data for Basel (with metadata for both sites
#'at once, i.e. "rhein" and "wiese")
#' @param analytics_dir Define directory with raw analytical data in CSV (.csv) format to
#' be imported (default: system.file("shiny/basel/data/analytics",
#' package = "aquanes.report"))
#' @param raw_dir_rhein Define directory for site "rhein" with raw data in
#' EXCEL spreadsheet format (.xlsx) to be imported (default:
#' system.file("shiny/basel/data/operation/rhein", package = "aquanes.report"))
#' @param raw_dir_wiese Define directory for site "rhein" with raw data in
#' EXCEL spreadsheet format (.xlsx) to be imported (default:
#' system.file("shiny/basel/data/operation/wiese", package = "aquanes.report"))
#' @param meta_online_path path to file containing metadata for online data
#' (default: system.file("shiny/basel/data/metadata/meta_online.csv",
#' package = "aquanes.report"))
#' @param meta_parameter_path Define path of "meta_parameter.csv" to be imported
#' (default: system.file("shiny/basel/data/metadata/meta_parameter.csv",
#' package = "aquanes.report"))
#' @param meta_site_path Define path of "meta_site.csv" to be imported
#' (default: system.file("shiny/basel/data/metadata/meta_site.csv",
#' package = "aquanes.report"))
#' @return data.frame with analytical & operational data for Basel
#' @importFrom plyr rbind.fill
#' @export
import_data_basel <- function(
analytics_dir = system.file("shiny/basel/data/analytics",
package = "aquanes.report"),
raw_dir_rhein = system.file("shiny/basel/data/operation/rhein",
package = "aquanes.report"),
raw_dir_wiese = system.file("shiny/basel/data/operation/wiese",
package = "aquanes.report"),
meta_online_path = system.file("shiny/basel/data/metadata/meta_online.csv",
package = "aquanes.report"),
meta_parameter_path = system.file("shiny/basel/data/metadata/meta_parameter.csv",
package = "aquanes.report"),
meta_site_path = system.file("shiny/basel/data/metadata/meta_site.csv",
package = "aquanes.report")) {


  operation_meta <- import_operation_meta_basel(raw_dir_rhein = raw_dir_rhein,
                                                raw_dir_wiese = raw_dir_wiese,
                                                meta_online_path = meta_online_path,
                                                meta_site_path = meta_site_path,
                                                meta_parameter_path = meta_parameter_path)
  analytics_meta <- import_analytics_meta_basel(analytics_dir = analytics_dir,
                                                meta_site_path = meta_site_path,
                                                meta_parameter_path = meta_parameter_path)


  print("###################################################################")
  print("######## Add analytical to the operational data (including metadata)")
  print("###################################################################")
  data_basel <- plyr::rbind.fill(operation_meta, analytics_meta)

  return(data_basel)
}



