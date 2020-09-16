
<!-- README.md is generated from README.Rmd. Please edit that file -->

tibblify
========

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/tibblify)](https://CRAN.R-project.org/package=tibblify)
[![Codecov test
coverage](https://codecov.io/gh/mgirlich/tibblify/branch/master/graph/badge.svg)](https://codecov.io/gh/mgirlich/tibblify?branch=master)
[![R build
status](https://github.com/mgirlich/tibblify/workflows/R-CMD-check/badge.svg)](https://github.com/mgirlich/tibblify/actions)
<!-- badges: end -->

The goal of tibblify is to provide an easy way of converting a nested
list into a tibble.

Installation
------------

You can install the released version of tibblify from
[CRAN](https://CRAN.R-project.org) with:

    install.packages("tibblify")

Or install the development version from GitHub with:

    # install.packages("devtools")
    devtools::install_github("mgirlich/tibblify")

Usage
-----

Let’s convert the Leaders dataset into a tibble. It is a list with one
element per character:

    library(tibblify)

    str(politicians[1])
    #> List of 1
    #>  $ :List of 8
    #>   ..$ id        : int 1
    #>   ..$ name      : chr "Barack"
    #>   ..$ surname   : chr "Obama"
    #>   ..$ dob       : chr "1961-08-04"
    #>   ..$ n_children: num 2
    #>   ..$ parents   :List of 2
    #>   .. ..$ mother: chr "Ann Dunham"
    #>   .. ..$ father: chr "Barack Obama Sr."
    #>   ..$ spouses   :List of 1
    #>   .. ..$ : chr "Michelle Robinson"
    #>   ..$ offices   :List of 2
    #>   .. ..$ :List of 2
    #>   .. .. ..$ name : chr "President of the United States"
    #>   .. .. ..$ start: chr "2009-01-20"
    #>   .. ..$ :List of 2
    #>   .. .. ..$ name : chr "United States Senator from Illinois"
    #>   .. .. ..$ start: chr "2005-01-03"

We can let `tibblify()` automatically recognize the structure of the
list and find an appropriate presentation as a tibble:

    politicians_tibble <- tibblify(politicians)
    politicians_tibble
    #> # A tibble: 2 x 8
    #>      id name   surname dob    n_children parents$mother $father spouses  offices
    #>   <int> <chr>  <chr>   <chr>       <dbl> <chr>          <chr>   <list<> <list<t>
    #> 1     1 Barack Obama   1961-…          2 Ann Dunham     Barack…     [1]  [2 × 2]
    #> 2     2 Boris  Johnson 1964-…         NA <NA>           Stanle…     [2]  [3 × 2]

The `parents` column is a tibble with the columns `mother` and `father`
because in the original list `leader1` the field `parents` is a named
list.

    politicians_tibble$parents
    #> # A tibble: 2 x 2
    #>   mother     father          
    #>   <chr>      <chr>           
    #> 1 Ann Dunham Barack Obama Sr.
    #> 2 <NA>       Stanley Johnson

and the `spouses` column is a
[`list_of`](https://vctrs.r-lib.org/reference/list_of.html) character
because the `spouses` field is a list and all elements are characters

    politicians_tibble$spouses
    #> <list_of<character>[2]>
    #> [[1]]
    #> [1] "Michelle Robinson"
    #> 
    #> [[2]]
    #> [1] "Allegra Mostyn-Owen" "Marina Wheeler"

Specification
-------------

In the above example we used `tibblify()` without any further
specification on how to convert the list into a tibble. This is quite
useful in an interactive session but often you want to provide a
specification yourself. Some of the reasons are:

-   to ensure type and shape stability of the resulting tibble in
    automated scripts.
-   to use a different type of a column.
-   to use different names.
-   to parse only a subset of columns.
-   to specify what happens if a value is missing.

First, we use `get_spec()` to view the specification used to convert our
list to a tibble:

    get_spec(politicians_tibble)
    #> lcols(
    #>   id = lcol_int("id"),
    #>   name = lcol_chr("name"),
    #>   surname = lcol_chr("surname"),
    #>   dob = lcol_chr("dob"),
    #>   n_children = lcol_dbl("n_children", .default = NA),
    #>   parents = lcol_df(
    #>     "parents",
    #>     mother = lcol_chr("mother", .default = NA),
    #>     father = lcol_chr("father")
    #>   ),
    #>   spouses = lcol_lst_of(
    #>     "spouses",
    #>     .ptype = character(0),
    #>     .parser = ~vec_c(!!!.x, .ptype = character()),
    #>     .default = NULL
    #>   ),
    #>   offices = lcol_df_lst(
    #>     "offices",
    #>     name = lcol_chr("name"),
    #>     start = lcol_chr("start")
    #>   )
    #> )

A specification always starts with a call to `lcols()` (similar to
[`readr::cols()`](https://readr.tidyverse.org/reference/cols.html)).
Then you specify the columns you want with name-value pairs. The name is
the name of the resulting column and the value is a specification
created with one of the `lcol_*()` functions.

Path
----

The first argument to `lcol_*()` is always a `path` which describes
where to find the element. The syntax is the same as in `purrr::map()`
used to extract fields. Some examples

    leader <- politicians[[1]]

    # get the element `id`
    path <- c("id")
    leader[["id"]]
    #> [1] 1

    # get the element `father` in the element `parents`
    path <- c("parents", "father")
    leader[["parents"]][["mother"]]
    #> [1] "Ann Dunham"

    # get the first element in the element `spouses`
    path <- list("spouses", 1)
    leader[["spouses"]][[1]]
    #> [1] "Michelle Robinson"

Vector Columns
--------------

A couple of typical vector types have a predefined extractor:

-   `lcol_chr()`: create a character column.
-   `lcol_lgl()`: create a logical column.
-   `lcol_int()`: create an integer column.
-   `lcol_dbl()`: create a double column.
-   `lcol_dat()`: create a date column.
-   `lcol_dtt()`: create a datetime column.

See [parsing other types](#parsing-other-types) to create a column of
your own prototype.

    tibblify(
      politicians,
      lcols(
        lcol_int("id"),
        lcol_chr("name"),
        `family name` = lcol_chr("surname")
      )
    )
    #> # A tibble: 2 x 3
    #>      id name   `family name`
    #>   <int> <chr>  <chr>        
    #> 1     1 Barack Obama        
    #> 2     2 Boris  Johnson

Missing Elements
----------------

If an element doesn’t exist an error is thrown as in `purrr::chuck()`.
To use a default value instead of throwing an error use the `.default`
argument. The `.default` value is also used in case the element at the
path is empty:

    list_default <- list(
      list(a = 1),
      list(a = NULL),
      list(a = integer()),
      list()
    )

    tibblify(
      list_default,
      lcols(lcol_int("a"))
    )
    #> Error: empty or absent element at path a

    tibblify(
      list_default,
      lcols(lcol_int("a", .default = 0))
    )
    #> # A tibble: 4 x 1
    #>       a
    #>   <int>
    #> 1     1
    #> 2     0
    #> 3     0
    #> 4     0

Parser
------

When the cast is not possible with `vctrs::vec_cast()` you can use the
`.parser` argument to supply a custom parser. It is passed to
`rlang::as_function()` so you can use a function or a formula. A typical
use case are dates stored as strings.

    tibblify(
      politicians,
      lcols(
        lcol_chr("surname"),
        lcol_dat("dob", .parser = ~ as.Date(.x, format = "%Y-%m-%d"))
      )
    )
    #> # A tibble: 2 x 2
    #>   surname dob       
    #>   <chr>   <date>    
    #> 1 Obama   1961-08-04
    #> 2 Johnson 1964-06-19

List and List Of Columns
------------------------

A `list_of` is a list where each element in the list has the same
prototype. It is useful when you have fields with more than one element
as in the `spouses` field.

    spouses_tbl <- tibblify(
      politicians,
      lcols(
        lcol_chr("surname"),
        lcol_lst_of("spouses", .ptype = character())
      )
    )

    spouses_tbl$spouses
    #> <list_of<character>[2]>
    #> [[1]]
    #> [[1]][[1]]
    #> [1] "Michelle Robinson"
    #> 
    #> 
    #> [[2]]
    #> [[2]][[1]]
    #> [1] "Allegra Mostyn-Owen"
    #> 
    #> [[2]][[2]]
    #> [1] "Marina Wheeler"

You can use
[`tidyr::unnest()`](https://tidyr.tidyverse.org/reference/nest.html) or
[`tidyr::unnest_longer()`](https://tidyr.tidyverse.org/reference/hoist.html)
to flatten these columns to regular columns.

A list column is used when you have a field with mixed elements.

Guess and Skip
--------------

Analogue to `readr::col_guess()` and `readr::col_skip()` you can specify
that you want to guess the column type with `lcol_guess()` respectively
skip a field with `lcol_skip()`. Skipping a column can be useful when
you set a default column type or you want to make clear that you know
about the field and intentionally skip it.

Guessing a column is useful in interactive sessions but you shouldn’t
rely on it in automated scripts.

Tibble Columns and List Of Tibble Columns
-----------------------------------------

If a field contains is a named list where each element has length 1 or 0
the field is converted to a tibble column. This is for example the case
for the `parents` field:

    leaders_tibble <- tibblify(
      politicians,
      lcols(
        lcol_chr("surname"),
        lcol_guess("parents")
      )
    )

    leaders_tibble
    #> # A tibble: 2 x 2
    #>   surname parents$mother $father         
    #>   <chr>   <chr>          <chr>           
    #> 1 Obama   Ann Dunham     Barack Obama Sr.
    #> 2 Johnson <NA>           Stanley Johnson

Tibble columns are a relatively new concept in the tidyverse. You can
unpack a tibble column into regular columns with `tidyr::unpack()`.

Parsing other types
-------------------

`tibblify` provides shortcuts for a couple of common types. To parse a
vector or record type without a parser use `lcol_vec()`. Let’s say you
have a list with `difftimes`

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

You need to define a prototype

    ptype <- as.difftime(0, units = "secs")
    ptype
    #> Time difference of 0 secs

and then use it in `lcol_vec()`

    tibblify(
      x,
      lcols(
        lcol_vec("timediff", ptype = ptype)
      )
    )
    #> # A tibble: 2 x 1
    #>   timediff
    #>   <drtn>  
    #> 1 100 secs
    #> 2 200 secs

Default Column Type
-------------------

You can use the `.default` argument of `lcols()` to define a parser used
for all unspecified fields.

    tibblify(
      politicians,
      lcols(
        lcol_chr("name"),
        lcol_chr("surname"),
        .default = lcol_lst(path = zap(), .default = NULL)
      )
    )
    #> # A tibble: 2 x 8
    #>   name   surname id       dob      n_children parents        spouses   offices  
    #>   <chr>  <chr>   <list>   <list>   <list>     <list>         <list>    <list>   
    #> 1 Barack Obama   <int [1… <chr [1… <dbl [1]>  <named list [… <list [1… <list [2…
    #> 2 Boris  Johnson <int [1… <chr [1… <NULL>     <named list [… <list [2… <list [3…

Code of Conduct
---------------

Please note that the tibblify project is released with a [Contributor
Code of
Conduct](https://www.contributor-covenant.org/version/2/0/code_of_conduct/).
By contributing to this project, you agree to abide by its terms.
