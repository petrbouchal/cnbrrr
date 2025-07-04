% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/arad_api.R
\name{arad_get_data}
\alias{arad_get_data}
\title{Retrieve data from ARAD API}
\usage{
arad_get_data(
  indicator_ids = NULL,
  set_id = NULL,
  base_id = NULL,
  selection_id = NULL,
  period_from = NULL,
  period_to = NULL,
  months_before = NULL,
  rename_value = NULL,
  api_key = NULL,
  base_url = "https://www.cnb.cz/aradb/api/v1",
  process_data = TRUE,
  encoding = "windows-1250",
  dest_dir = NULL,
  force_redownload = FALSE
)
}
\arguments{
\item{indicator_ids}{Character vector of indicator IDs to retrieve (primary method)}

\item{set_id}{Character, set ID to retrieve data from a specific data set}

\item{base_id}{Character, base ID to retrieve data for specific base indicators}

\item{selection_id}{Character, ID of a named selection created in ARAD user account}

\item{period_from}{Character, start date in YYYYMMDD format (e.g., "20200101")}

\item{period_to}{Character, end date in YYYYMMDD format (e.g., "20231231")}

\item{months_before}{Integer, number of months before current date to retrieve data for}

\item{rename_value}{Character, new name for the 'value' column in the output}

\item{api_key}{API key for ARAD access. If NULL, uses ARAD_API_KEY environment variable}

\item{base_url}{Base URL for the ARAD API}

\item{process_data}{Logical, whether to process the raw data (default TRUE)}

\item{encoding}{Character encoding for the response (default "windows-1250")}

\item{dest_dir}{Character, directory where downloaded files are saved. Defaults to getOption("cnbrrr.dest_dir", tempdir())}

\item{force_redownload}{Logical, if TRUE forces redownload even if file exists (default FALSE)}
}
\value{
A data frame with the requested data
}
\description{
This function retrieves data from the Czech National Bank's ARAD API
for specified indicators. Data can be retrieved by indicator IDs, set ID, base ID,
or selection ID, with optional date filtering and value column renaming.
}
\examples{
\dontrun{
# Get data for a single indicator
data <- arad_get_data("SRUMD08402C")

# Get data for multiple indicators
data <- arad_get_data(c("SRUMD08402C", "ANOTHER_ID"))

# Get data with date filtering
data <- arad_get_data("SRUMD08402C",
                      period_from = "20200101",
                      period_to = "20231231")

# Get data from a set ID
data <- arad_get_data(set_id = "1115")

# Get data from a selection with custom value column name
data <- arad_get_data(selection_id = "my_selection",
                      rename_value = "spending")

# Get recent data using months_before
recent_data <- arad_get_data("SRUMD08402C", months_before = 12)

# Save data to specific directory
data <- arad_get_data("SRUMD08402C", dest_dir = "./data")

# Force redownload of existing data
fresh_data <- arad_get_data("SRUMD08402C", force_redownload = TRUE)

# Set global destination directory
options(cnbrrr.dest_dir = "~/cnb_data")
data <- arad_get_data("SRUMD08402C")  # Will use ~/cnb_data
}
}
