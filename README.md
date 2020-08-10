
<!-- README.md is generated from README.Rmd. Please edit that file -->

# listparser

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/listparser)](https://CRAN.R-project.org/package=listparser)
<!-- badges: end -->

The goal of listparser is to …

## Installation

You can install the released version of listparser from
[CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("listparser")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(listparser)

str(got_chars[[1]])
#> List of 18
#>  $ url        : chr "https://www.anapioficeandfire.com/api/characters/1022"
#>  $ id         : int 1022
#>  $ name       : chr "Theon Greyjoy"
#>  $ gender     : chr "Male"
#>  $ culture    : chr "Ironborn"
#>  $ born       : chr "In 278 AC or 279 AC, at Pyke"
#>  $ died       : chr ""
#>  $ alive      : logi TRUE
#>  $ titles     : chr [1:3] "Prince of Winterfell" "Captain of Sea Bitch" "Lord of the Iron Islands (by law of the green lands)"
#>  $ aliases    : chr [1:4] "Prince of Fools" "Theon Turncloak" "Reek" "Theon Kinslayer"
#>  $ father     : chr ""
#>  $ mother     : chr ""
#>  $ spouse     : chr ""
#>  $ allegiances: chr "House Greyjoy of Pyke"
#>  $ books      : chr [1:3] "A Game of Thrones" "A Storm of Swords" "A Feast for Crows"
#>  $ povBooks   : chr [1:2] "A Clash of Kings" "A Dance with Dragons"
#>  $ tvSeries   : chr [1:6] "Season 1" "Season 2" "Season 3" "Season 4" ...
#>  $ playedBy   : chr "Alfie Allen"
```

``` r
got_chars_tibble <- tibblify(got_chars)
dplyr::glimpse(got_chars_tibble)
#> Rows: 30
#> Columns: 18
#> $ url         <chr> "https://www.anapioficeandfire.com/api/characters/1022", …
#> $ id          <int> 1022, 1052, 1074, 1109, 1166, 1267, 1295, 130, 1303, 1319…
#> $ name        <chr> "Theon Greyjoy", "Tyrion Lannister", "Victarion Greyjoy",…
#> $ gender      <chr> "Male", "Male", "Male", "Male", "Male", "Male", "Male", "…
#> $ culture     <chr> "Ironborn", "", "Ironborn", "", "Norvoshi", "", "", "Dorn…
#> $ born        <chr> "In 278 AC or 279 AC, at Pyke", "In 273 AC, at Casterly R…
#> $ died        <chr> "", "", "", "In 297 AC, at Haunted Forest", "", "In 299 A…
#> $ alive       <lgl> TRUE, TRUE, TRUE, FALSE, TRUE, FALSE, FALSE, TRUE, TRUE, …
#> $ titles      <list<chr>> [<"Prince of Winterfell", "Captain of Sea Bitch", "…
#> $ aliases     <list<chr>> [<"Prince of Fools", "Theon Turncloak", "Reek", "Th…
#> $ father      <chr> "", "", "", "", "", "", "", "", "", "", "", "", "", "", "…
#> $ mother      <chr> "", "", "", "", "", "", "", "", "", "", "", "", "", "", "…
#> $ spouse      <chr> "", "https://www.anapioficeandfire.com/api/characters/204…
#> $ allegiances <list<chr>> ["House Greyjoy of Pyke", "House Lannister of Caste…
#> $ books       <list<chr>> [<"A Game of Thrones", "A Storm of Swords", "A Feas…
#> $ povBooks    <list<chr>> [<"A Clash of Kings", "A Dance with Dragons">, <"A …
#> $ tvSeries    <list<chr>> [<"Season 1", "Season 2", "Season 3", "Season 4", "…
#> $ playedBy    <list<chr>> ["Alfie Allen", "Peter Dinklage", "", "Bronson Webb…
```

``` r
get_spec(got_chars_tibble)
#> lcols(
#>   url = lcol_chr("url"),
#>   id = lcol_int("id"),
#>   name = lcol_chr("name"),
#>   gender = lcol_chr("gender"),
#>   culture = lcol_chr("culture"),
#>   born = lcol_chr("born"),
#>   died = lcol_chr("died"),
#>   alive = lcol_lgl("alive"),
#>   titles = lcol_lst_flat("titles", .ptype = character(0)),
#>   aliases = lcol_lst_flat(
#>     "aliases",
#>     .ptype = character(0),
#>     .default = NULL
#>   ),
#>   father = lcol_chr("father"),
#>   mother = lcol_chr("mother"),
#>   spouse = lcol_chr("spouse"),
#>   allegiances = lcol_lst_flat(
#>     "allegiances",
#>     .ptype = character(0),
#>     .default = NULL
#>   ),
#>   books = lcol_lst_flat(
#>     "books",
#>     .ptype = character(0),
#>     .default = NULL
#>   ),
#>   povBooks = lcol_lst_flat("povBooks", .ptype = character(0)),
#>   tvSeries = lcol_lst_flat("tvSeries", .ptype = character(0)),
#>   playedBy = lcol_lst_flat("playedBy", .ptype = character(0)),
#>   .default = lcol_guess(zap(), .default = NULL)
#> )
```

``` r
tibblify(
  got_chars,
  lcols(
    id = lcol_int("id"),
    name = lcol_chr("name"),
    gender = lcol_chr("gender"),
    aliases = lcol_lst_flat(
      "aliases",
      .ptype = character(0),
      .default = NULL
    ),
    allegiances = lcol_lst_flat(
      "allegiances",
      .ptype = character(0),
      .default = NULL
    )
  )
)
#> # A tibble: 30 x 5
#>       id name               gender     aliases allegiances
#>    <int> <chr>              <chr>  <list<chr>> <list<chr>>
#>  1  1022 Theon Greyjoy      Male           [4]         [1]
#>  2  1052 Tyrion Lannister   Male          [11]         [1]
#>  3  1074 Victarion Greyjoy  Male           [1]         [1]
#>  4  1109 Will               Male           [1]         [0]
#>  5  1166 Areo Hotah         Male           [1]         [1]
#>  6  1267 Chett              Male           [1]         [0]
#>  7  1295 Cressen            Male           [1]         [0]
#>  8   130 Arianne Martell    Female         [1]         [1]
#>  9  1303 Daenerys Targaryen Female        [11]         [1]
#> 10  1319 Davos Seaworth     Male           [5]         [2]
#> # … with 20 more rows
```

## Parsing other types

`listparser` provides shortcuts for a couple of common types. To parse a
type without a parser use `lcol_vec()`. For example to parse a list with
`difftimes`

``` r
now <- Sys.time()
past <- now - c(100, 200)

x <- list(
  list(timediff = now - past[1]),
  list(timediff = now - past[2])
)

x
#> [[1]]
#> [[1]]$timediff
#> Time difference of 1.666667 mins
#> 
#> 
#> [[2]]
#> [[2]]$timediff
#> Time difference of 3.333333 mins
```

``` r
ptype <- as.difftime(0, units = "secs")

tibblify(
  x,
  lcols(
    lcol_vec("timediff", ptype)
  )
)
#> # A tibble: 2 x 1
#>   timediff
#>   <drtn>  
#> 1 100 secs
#> 2 200 secs
```
