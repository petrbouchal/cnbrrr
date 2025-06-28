# cnbrrr: Interface to Czech National Bank ARAD Data API
Petr Bouchal

# cnbrrr

R package for accessing data from the Czech National Bank’s ARAD
(Aggregated data of the CNB) API.

The package is not affiliated in any way to the Czech National Bank but
I am grateful to them for proving the data and maintaining the
infrastructure.

## About ARAD

[ARAD](https://www.cnb.cz/arad/) is the Czech National Bank’s public
database containing aggregated economic and financial data. The system
provides access to:

- **Monetary policy indicators** - interest rates, money supply,
  exchange rates
- **Financial market data** - banking sector statistics, capital market
  indicators  
- **Macroeconomic statistics** - GDP, inflation, employment, government
  finances
- **Balance of payments** - current account, capital flows,
  international reserves
- **International comparisons** - harmonized indicators across countries

The data spans from the 1990s to present, with most series updated
monthly or quarterly. All data comes from the CNB’s statistical
processing and external statistical sources.

Comprehensive user guidance is at
<https://www.cnb.cz/arad/#/cs/documentation>.

## Package features

The `cnbrrr` package provides:

- **Data discovery**: listing indicators contained in a set or base
- **Metadata exploration** to discover available indicators and
  categories
- **Simple data retrieval** with automatic date parsing and formatting
- **Consistent data structure** across all functions

## Installation

``` r
# Install from GitHub
remotes::install_github("petrbouchal/cnbrrr")
```

## Setup

- obtain an API key from the Czech National Bank (requires registration)
- set it as an environment variable:

``` r
Sys.setenv(ARAD_API_KEY = "your_api_key_here")
```

## Quick example

``` r
library(cnbrrr)

# List available indicators from set (sestava), filter by name
indicators <- arad_list_indicators(set_id = 1032, filter = "domácnost")
```

    ℹ Using "','" as decimal and "'.'" as grouping mark. Use `read_delim()` for more control.

``` r
indicators
```

    # A tibble: 152 × 7
       indicator_id  indicator_name     frequency_code frequency_name unit_mult_code
       <chr>         <chr>              <chr>          <chr>          <chr>         
     1 SFU0QS15A01T  Finanční účty, Ak… Q              Čtvrtletní     6             
     2 SFU0QS15A01LE Finanční účty, Ak… Q              Čtvrtletní     6             
     3 SFU0QS15L01T  Finanční účty, Ak… Q              Čtvrtletní     6             
     4 SFU0QS15L01LE Finanční účty, Ak… Q              Čtvrtletní     6             
     5 SFU0QS14A01T  Finanční účty, Ak… Q              Čtvrtletní     6             
     6 SFU0QS14A01LE Finanční účty, Ak… Q              Čtvrtletní     6             
     7 SFU0QS14L01T  Finanční účty, Ak… Q              Čtvrtletní     6             
     8 SFU0QS14L01LE Finanční účty, Ak… Q              Čtvrtletní     6             
     9 SFU2QS14A05LE Finanční účty, F2… Q              Čtvrtletní     6             
    10 SFU2QS15A05T  Finanční účty, F2… Q              Čtvrtletní     6             
    # ℹ 142 more rows
    # ℹ 2 more variables: unit_mult_name <chr>, unit <chr>

Note there is no way to list all available indicators or to list bases
and sets - you need to have some idea of what you are looking for - for
that, check the website.

``` r
# Get data for a specific indicator  
data <- arad_get_data("SRUMD08402C")
```

    $api_key
    [1] "20252406003048901461901461UWHUTG2Q7CX2Y7PX"

    $indicator_id_list
    [1] "SRUMD08402C"

    ℹ Using "','" as decimal and "'.'" as grouping mark. Use `read_delim()` for more control.

``` r
data
```

    # A tibble: 389 × 6
       indicator_id snapshot_id period                value  year month
       <chr>        <chr>       <dttm>                <dbl> <dbl> <dbl>
     1 SRUMD08402C  <NA>        2025-05-31 00:00:00 9.45e11  2025     5
     2 SRUMD08402C  <NA>        2025-04-30 00:00:00 7.49e11  2025     4
     3 SRUMD08402C  <NA>        2025-03-31 00:00:00 5.68e11  2025     3
     4 SRUMD08402C  <NA>        2025-02-28 00:00:00 3.65e11  2025     2
     5 SRUMD08402C  <NA>        2025-01-31 00:00:00 1.73e11  2025     1
     6 SRUMD08402C  <NA>        2024-12-31 00:00:00 2.24e12  2024    12
     7 SRUMD08402C  <NA>        2024-11-30 00:00:00 2.00e12  2024    11
     8 SRUMD08402C  <NA>        2024-10-31 00:00:00 1.80e12  2024    10
     9 SRUMD08402C  <NA>        2024-09-30 00:00:00 1.63e12  2024     9
    10 SRUMD08402C  <NA>        2024-08-31 00:00:00 1.45e12  2024     8
    # ℹ 379 more rows

See the [Get started](articles/cnbrrr.html) vignette for detailed
workflows and examples.

## License

MIT License - see LICENSE file for details.
