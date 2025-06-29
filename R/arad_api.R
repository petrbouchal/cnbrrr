#' Retrieve data from ARAD API
#'
#' This function retrieves data from the Czech National Bank's ARAD API
#' for specified indicators. Data can be retrieved by indicator IDs, set ID, base ID,
#' or selection ID, with optional date filtering and value column renaming.
#'
#' @param indicator_ids Character vector of indicator IDs to retrieve (primary method)
#' @param set_id Character, set ID to retrieve data from a specific data set
#' @param base_id Character, base ID to retrieve data for specific base indicators
#' @param selection_id Character, ID of a named selection created in ARAD user account
#' @param period_from Character, start date in YYYYMMDD format (e.g., "20200101")
#' @param period_to Character, end date in YYYYMMDD format (e.g., "20231231")
#' @param months_before Integer, number of months before current date to retrieve data for
#' @param rename_value Character, new name for the 'value' column in the output
#' @param api_key API key for ARAD access. If NULL, uses ARAD_API_KEY environment variable
#' @param base_url Base URL for the ARAD API
#' @param process_data Logical, whether to process the raw data (default TRUE)
#' @param encoding Character encoding for the response (default "windows-1250")
#' @param dest_dir Character, directory where downloaded files are saved. Defaults to getOption("cnbrrr.dest_dir", tempdir())
#' @param force_redownload Logical, if TRUE forces redownload even if file exists (default FALSE)
#'
#' @return A data frame with the requested data
#' @export
#'
#' @examples
#' \dontrun{
#' # Get data for a single indicator
#' data <- arad_get_data("SRUMD08402C")
#'
#' # Get data for multiple indicators
#' data <- arad_get_data(c("SRUMD08402C", "ANOTHER_ID"))
#'
#' # Get data with date filtering
#' data <- arad_get_data("SRUMD08402C",
#'                       period_from = "20200101",
#'                       period_to = "20231231")
#'
#' # Get data from a set ID
#' data <- arad_get_data(set_id = "1115")
#'
#' # Get data from a selection with custom value column name
#' data <- arad_get_data(selection_id = "my_selection",
#'                       rename_value = "spending")
#'
#' # Get recent data using months_before
#' recent_data <- arad_get_data("SRUMD08402C", months_before = 12)
#'
#' # Save data to specific directory
#' data <- arad_get_data("SRUMD08402C", dest_dir = "./data")
#'
#' # Force redownload of existing data
#' fresh_data <- arad_get_data("SRUMD08402C", force_redownload = TRUE)
#'
#' # Set global destination directory
#' options(cnbrrr.dest_dir = "~/cnb_data")
#' data <- arad_get_data("SRUMD08402C")  # Will use ~/cnb_data
#' }
arad_get_data <- function(indicator_ids = NULL,
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
                          force_redownload = FALSE) {

  if (is.null(api_key)) {
    api_key <- Sys.getenv("ARAD_API_KEY")
    if (api_key == "") {
      stop("API key not provided. Set ARAD_API_KEY environment variable or provide api_key parameter.")
    }
  }

  if (length(indicator_ids) == 0) {
    stop("At least one indicator ID must be provided.")
  }

  if (is.null(dest_dir)) {
    dest_dir <- getOption("cnbrrr.dest_dir", tempdir())
  }

  indicator_list <- paste(indicator_ids, collapse = ",")
  file_id <- paste(sort(indicator_ids), collapse = "_")
  if (!is.null(set_id)) file_id <- paste(file_id, set_id, sep = "_")
  if (!is.null(base_id)) file_id <- paste(file_id, base_id, sep = "_")
  if (!is.null(selection_id)) file_id <- paste(file_id, selection_id, sep = "_")
  if (!is.null(period_from)) file_id <- paste(file_id, period_from, sep = "_")
  if (!is.null(period_to)) file_id <- paste(file_id, period_to, sep = "_")
  if (!is.null(months_before)) file_id <- paste(file_id, months_before, sep = "_")
  
  file_path <- file.path(dest_dir, paste0("arad_", file_id, ".csv"))
  
  if (file.exists(file_path) && !force_redownload) {
    message("File already exists at ", file_path, ". Loading from cache. Use force_redownload = TRUE to redownload.")
    if (!process_data) {
      return(readBin(file_path, "raw", file.info(file_path)$size))
    }
    data <- readr::read_csv2(file_path,
                            locale = readr::locale(encoding = encoding),
                            col_types = "cccd")
    
    if (nrow(data) > 0 && "period" %in% names(data)) {
      data <- data |>
        dplyr::mutate(
          period = lubridate::parse_date_time(period, orders = "%Y%m%d"),
          year = lubridate::year(period),
          month = lubridate::month(period)
        )
    }
    
    if (!is.null(rename_value) && "value" %in% names(data)) {
      data <- data |> dplyr::rename(!!rename_value := value)
    }
    
    return(data)
  }

  query_list <- list(api_key = api_key)

  if(!is.null(indicator_ids)) query_list$indicator_id_list <- indicator_list
  if(!is.null(base_id)) query_list$base_id <- base_id
  if(!is.null(months_before)) query_list$months_before <- months_before
  if(!is.null(set_id)) query_list$set_id <- set_id
  if(!is.null(selection_id)) query_list$selection_id <- selection_id
  if(!is.null(period_from)) query_list$period_from <- period_from
  if(!is.null(period_from)) query_list$period_from <- period_from
  if(!is.null(period_to)) query_list$period_to <- period_to

  tryCatch({
    response <- httr2::request(base_url) |>
      httr2::req_url_path_append("data") |>
      httr2::req_url_query(!!!query_list) |>
      httr2::req_perform()
  }, error = function(e) {
    stop("Failed to retrieve data from ARAD API: ", e$message)
  })

  raw_data <- httr2::resp_body_raw(response)

  dir.create(dirname(file_path), showWarnings = FALSE, recursive = TRUE)
  writeLines(rawToChar(raw_data), file_path)

  if (!process_data) {
    return(readBin(file_path, "raw", file.info(file_path)$size))
  }

  data <- readr::read_csv2(file_path,
                          locale = readr::locale(encoding = encoding),
                          col_types = "cccd")

  if (nrow(data) > 0 && "period" %in% names(data)) {
    data <- data |>
      dplyr::mutate(
        period = lubridate::parse_date_time(period, orders = "%Y%m%d"),
        year = lubridate::year(period),
        month = lubridate::month(period)
      )
  }

  if (!is.null(rename_value) && "value" %in% names(data)) {
    data <- data |> dplyr::rename(!!rename_value := value)
  }

  return(data)
}

#' List available indicators from ARAD API
#'
#' This function retrieves the list of available indicators from the ARAD API.
#' You can filter the results by providing a search term that will match indicator
#' names (case-insensitive).
#'
#' To use this function effectively, you need to understand ARAD's structure:
#' - **set_id**: Identifies a data set (collection of related indicators)
#' - **base_id**: Identifies the base indicator within a set
#' - Find these IDs by browsing the ARAD web interface at https://www.cnb.cz/arad/
#'
#' @param set_id Character, set ID to filter indicators from a specific data set (required unless base_id, indicator_id_list, or selection_id is provided)
#' @param base_id Character, base ID to filter specific indicators (required unless set_id, indicator_id_list, or selection_id is provided)
#' @param indicator_id_list Character vector, specific indicator IDs to retrieve (required unless set_id, base_id, or selection_id is provided). Will be converted to comma-separated string.
#' @param selection_id Character, ID of a named selection created in ARAD user account (required unless set_id, base_id, or indicator_id_list is provided)
#' @param filter Character, optional search term to filter indicator names (case-insensitive)
#' @param api_key API key for ARAD access. If NULL, uses ARAD_API_KEY environment variable
#' @param base_url Base URL for the ARAD API
#' @param encoding Character encoding for the response (default "windows-1250")
#'
#' @return A data frame with available indicators and their metadata
#' @export
#'
#' @examples
#' \dontrun{
#' # Get all available indicators
#' indicators <- arad_list_indicators()
#'
#' # Filter indicators by name (case-insensitive)
#' gdp_indicators <- arad_list_indicators(filter = "GDP")
#'
#' # Get indicators from a specific data set
#' monetary_indicators <- arad_list_indicators(set_id = "MONETARY_SET")
#'
#' # Get specific indicator by base_id (base part without suffix)
#' specific_indicator <- arad_list_indicators(base_id = "SRUMD084")
#'
#' # Get specific indicators by indicator IDs
#' specific_indicators <- arad_list_indicators(indicator_id_list = "SRUMD08402")
#' multiple_indicators <- arad_list_indicators(indicator_id_list = c("SRUMD08402", "SRUMD08403"))
#'
#' # Get indicators from a named selection
#' selection_indicators <- arad_list_indicators(selection_id = "my_selection")
#' }
arad_list_indicators <- function(set_id = NULL,
                                base_id = NULL,
                                indicator_id_list = NULL,
                                selection_id = NULL,
                                filter = NULL,
                                api_key = NULL,
                                base_url = "https://www.cnb.cz/aradb/api/v1",
                                encoding = "windows-1250") {

  if (is.null(api_key)) {
    api_key <- Sys.getenv("ARAD_API_KEY")
    if (api_key == "") {
      stop("API key not provided. Set ARAD_API_KEY environment variable or provide api_key parameter.")
    }
  }

  # Check that at least one of set_id, base_id, indicator_id_list, or selection_id is provided
  if (is.null(set_id) && is.null(base_id) && is.null(indicator_id_list) && is.null(selection_id)) {
    stop("Either 'set_id', 'base_id', 'indicator_id_list', or 'selection_id' must be provided. Find these IDs by browsing https://www.cnb.cz/arad/")
  }

  query_params <- list(api_key = api_key)

  if (!is.null(set_id)) {
    query_params$set_id <- set_id
  }

  if (!is.null(base_id)) {
    query_params$base_id <- base_id
  }

  if (!is.null(indicator_id_list)) {
    # Convert vector to comma-separated string
    query_params$indicator_id_list <- paste(indicator_id_list, collapse = ",")
  }

  if (!is.null(selection_id)) {
    query_params$selection_id <- selection_id
  }

  tryCatch({
    response <- httr2::request(base_url) |>
      httr2::req_url_path_append("indicators") |>
      httr2::req_url_query(!!!query_params) |>
      httr2::req_perform()
  }, error = function(e) {
    stop("Failed to retrieve indicators from ARAD API: ", e$message)
  })

  raw_data <- httr2::resp_body_raw(response)

  temp_file <- tempfile(fileext = ".csv")
  on.exit(unlink(temp_file))

  writeLines(rawToChar(raw_data), temp_file)

  indicators <- readr::read_csv2(temp_file,
                                locale = readr::locale(encoding = encoding),
                                col_types = readr::cols(.default = "c"))

  # Apply filter if provided (case-insensitive search in indicator names)
  if (!is.null(filter) && nrow(indicators) > 0) {
    if ("name" %in% names(indicators)) {
      indicators <- indicators[grepl(filter, indicators$name, ignore.case = TRUE), ]
    } else if ("indicator_name" %in% names(indicators)) {
      indicators <- indicators[grepl(filter, indicators$indicator_name, ignore.case = TRUE), ]
    } else {
      warning("No name column found in indicators data. Filter not applied.")
    }
  }

  return(indicators)
}

#' Get indicator dimensions from ARAD API
#'
#' This function retrieves the dimensional structure of indicators from the ARAD API,
#' showing how indicators are organized and what dimensions are available.
#'
#' @param set_id Character, set ID to get dimensions for a specific data set (required unless indicator_id_list or selection_id is provided)
#' @param indicator_id_list Character vector, specific indicator IDs to retrieve dimensions for (required unless set_id or selection_id is provided). Will be converted to comma-separated string.
#' @param selection_id Character, ID of a named selection created in ARAD user account (required unless set_id or indicator_id_list is provided)
#' @param api_key API key for ARAD access. If NULL, uses ARAD_API_KEY environment variable
#' @param base_url Base URL for the ARAD API
#' @param encoding Character encoding for the response (default "windows-1250")
#'
#' @return A data frame with indicator dimensions
#' @export
#'
#' @examples
#' \dontrun{
#' # Get all indicator dimensions
#' dimensions <- arad_indicators_dims()
#'
#' # Get dimensions for a specific data set
#' monetary_dims <- arad_indicators_dims(set_id = "MONETARY_SET")
#'
#' # Get dimensions for specific indicators
#' specific_dims <- arad_indicators_dims(indicator_id_list = "SRUMD08402")
#' multiple_dims <- arad_indicators_dims(indicator_id_list = c("SRUMD08402", "SRUMD08403"))
#'
#' # Get dimensions from a named selection
#' selection_dims <- arad_indicators_dims(selection_id = "my_selection")
#' }
arad_indicators_dims <- function(set_id = NULL,
                                indicator_id_list = NULL,
                                selection_id = NULL,
                                api_key = NULL,
                                base_url = "https://www.cnb.cz/aradb/api/v1",
                                encoding = "windows-1250") {

  if (is.null(api_key)) {
    api_key <- Sys.getenv("ARAD_API_KEY")
    if (api_key == "") {
      stop("API key not provided. Set ARAD_API_KEY environment variable or provide api_key parameter.")
    }
  }

  # Check that at least one of set_id, indicator_id_list, or selection_id is provided
  if (is.null(set_id) && is.null(indicator_id_list) && is.null(selection_id)) {
    stop("Either 'set_id', 'indicator_id_list', or 'selection_id' must be provided. Find these IDs by browsing https://www.cnb.cz/arad/")
  }

  query_params <- list(api_key = api_key)

  if (!is.null(set_id)) {
    query_params$set_id <- set_id
  }

  if (!is.null(indicator_id_list)) {
    # Convert vector to comma-separated string
    query_params$indicator_id_list <- paste(indicator_id_list, collapse = ",")
  }

  if (!is.null(selection_id)) {
    query_params$selection_id <- selection_id
  }

  tryCatch({
    response <- httr2::request(base_url) |>
      httr2::req_url_path_append("indicators-dims") |>
      httr2::req_url_query(!!!query_params) |>
      httr2::req_perform()
  }, error = function(e) {
    stop("Failed to retrieve indicator dimensions from ARAD API: ", e$message)
  })

  raw_data <- httr2::resp_body_raw(response)

  temp_file <- tempfile(fileext = ".csv")
  on.exit(unlink(temp_file))

  writeLines(rawToChar(raw_data), temp_file)

  dimensions <- readr::read_csv2(temp_file,
                                locale = readr::locale(encoding = encoding),
                                col_types = readr::cols(.default = "c"))

  return(dimensions)
}

#' Get indicator tree structure from ARAD API
#'
#' This function retrieves the hierarchical tree structure of indicators from the ARAD API,
#' showing how indicators are organized in a tree format with categories and subcategories.
#'
#' @param set_id Character, set ID to get tree structure for a specific data set (required unless indicator_id_list or selection_id is provided)
#' @param indicator_id_list Character vector, specific indicator IDs to retrieve tree structure for (required unless set_id or selection_id is provided). Will be converted to comma-separated string.
#' @param selection_id Character, ID of a named selection created in ARAD user account (required unless set_id or indicator_id_list is provided)
#' @param api_key API key for ARAD access. If NULL, uses ARAD_API_KEY environment variable
#' @param base_url Base URL for the ARAD API
#' @param encoding Character encoding for the response (default "windows-1250")
#'
#' @return A data frame with the hierarchical indicator tree structure
#' @export
#'
#' @examples
#' \dontrun{
#' # Get full indicator tree
#' tree <- arad_indicators_tree()
#'
#' # Get tree structure for a specific data set
#' monetary_tree <- arad_indicators_tree(set_id = "MONETARY_SET")
#'
#' # Get tree structure for specific indicators
#' specific_tree <- arad_indicators_tree(indicator_id_list = "SRUMD08402")
#' multiple_tree <- arad_indicators_tree(indicator_id_list = c("SRUMD08402", "SRUMD08403"))
#'
#' # Get tree structure from a named selection
#' selection_tree <- arad_indicators_tree(selection_id = "my_selection")
#' }
arad_indicators_tree <- function(set_id = NULL,
                                indicator_id_list = NULL,
                                selection_id = NULL,
                                api_key = NULL,
                                base_url = "https://www.cnb.cz/aradb/api/v1",
                                encoding = "windows-1250") {

  if (is.null(api_key)) {
    api_key <- Sys.getenv("ARAD_API_KEY")
    if (api_key == "") {
      stop("API key not provided. Set ARAD_API_KEY environment variable or provide api_key parameter.")
    }
  }

  # Check that at least one of set_id, indicator_id_list, or selection_id is provided
  if (is.null(set_id) && is.null(indicator_id_list) && is.null(selection_id)) {
    stop("Either 'set_id', 'indicator_id_list', or 'selection_id' must be provided. Find these IDs by browsing https://www.cnb.cz/arad/")
  }

  query_params <- list(api_key = api_key)

  if (!is.null(set_id)) {
    query_params$set_id <- set_id
  }

  if (!is.null(indicator_id_list)) {
    # Convert vector to comma-separated string
    query_params$indicator_id_list <- paste(indicator_id_list, collapse = ",")
  }

  if (!is.null(selection_id)) {
    query_params$selection_id <- selection_id
  }

  tryCatch({
    response <- httr2::request(base_url) |>
      httr2::req_url_path_append("indicators-tree") |>
      httr2::req_url_query(!!!query_params) |>
      httr2::req_perform()
  }, error = function(e) {
    stop("Failed to retrieve indicator tree from ARAD API: ", e$message)
  })

  raw_data <- httr2::resp_body_raw(response)

  temp_file <- tempfile(fileext = ".csv")
  on.exit(unlink(temp_file))

  writeLines(rawToChar(raw_data), temp_file)

  tree <- readr::read_csv2(temp_file,
                          locale = readr::locale(encoding = encoding),
                          col_types = readr::cols(.default = "c"))

  return(tree)
}

#' @rdname arad_list_indicators
#' @export
arad_get_indicators <- arad_list_indicators
