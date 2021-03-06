% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/import_operation_berlin_s.R
\name{import_data_berlin_s}
\alias{import_data_berlin_s}
\title{Import data for Berlin Schoenerlinde}
\usage{

  import_data_berlin_s(raw_data_dir = system.file("shiny/berlin_s/data/operation",
  package = "aquanes.report"), raw_data_files = NULL,
  meta_file_path = system.file("shiny/berlin_s/data/parameter_site_metadata.csv",
  package = "aquanes.report"))
}
\arguments{
\item{raw_data_dir}{path of directory containing WEDECO CSV files (default:
(default: system.file("shiny/berlin_s/data/operation",
package = "aquanes.report"))))}

\item{raw_data_files}{vector with full path to operational raw data files that
allows to limit import to specific files (default: NULL). If specified parameter
"raw_data_dir" will not be used}

\item{meta_file_path}{path to metadata file (default:
system.file("shiny/berlin_s/data/parameter_site_metadata.csv", package =
"aquanes.report")))}
}
\value{
list with "df": data.frame with imported operational data (analytics
data to be added as soon as available) and "added_data_points": number of
added data points in case of existing fst file was updated with new operational
data
}
\description{
Import data for Berlin Schoenerlinde
}
