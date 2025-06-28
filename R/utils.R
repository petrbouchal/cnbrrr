#' Convert ARAD period to Date
#'
#' Helper function to convert ARAD period format (YYYYMMDD) to Date object
#'
#' @param period_string Character vector of period strings
#' @return Date vector
#' @export
#'
#' @examples
#' \dontrun{
#' periods <- c("20231201", "20231101")
#' dates <- arad_parse_date(periods)
#' }
arad_parse_date <- function(period_string) {
  lubridate::parse_date_time(period_string, orders = "%Y%m%d")
}

#' Validate indicator IDs
#'
#' Helper function to validate ARAD indicator ID format
#'
#' @param indicator_ids Character vector of indicator IDs
#' @return Logical vector indicating valid IDs
#' @export
arad_validate_indicators <- function(indicator_ids) {
  pattern <- "^[A-Z0-9]+$"
  grepl(pattern, indicator_ids) & nchar(indicator_ids) > 0
}

