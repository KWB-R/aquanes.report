#'Wrapper for fst::read.fst to read DateTime column in POSIXct format
#'
#' @param path path to fst file
#' @param tz timezone of DateTime to be imported (default: "CET")
#' @param col_datetime column name containing numeric values in nanoseconds since
#' 1970-01-01 (default: "DateTime")
#' @param ... further arguments passed to fst::read.fst
#' @return data.frame with formatting of DateTime column POSIXct
#' @importFrom fst read.fst
#' @export
read_fst <- function(path,
                     tz = "CET",
                     col_datetime = "DateTime",
                     ...) {

df <- fst::read.fst(path,
                    ...)
df[,col_datetime] <- as.POSIXct(df[,col_datetime], origin = "1970-01-01",tz = "CET")
return(df)
}

