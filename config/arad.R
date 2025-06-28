library(httr2)
dta_arad <- httr2::request("https://www.cnb.cz") |> 
  req_url_path_append("/aradb/api/v1") |> 
  req_url_path_append("data") |> 
  req_url_query(indicator_id_list = "SRUMD08402C", api_key = Sys.getenv("ARAD_API_KEY")) |> 
  req_perform() |> 
  resp_body_raw()

writeLines(rawToChar(dta_arad), "arad.txt")

readr::guess_encoding("arad.txt")

vydaje_sr <- readr::read_csv2("arad.txt", locale = readr::locale(encoding = "windows-1250"), 
                 col_types = "cccd") |> 
  mutate(period = lubridate::parse_date_time(period, orders = "%Y%m%d"),
         rok = lubridate::year(period)) |> 
  filter(lubridate::month(period) == 12) |>
  rename(vydaje_sr = value)