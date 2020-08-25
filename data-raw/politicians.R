## code to prepare `leaders_simple` dataset goes here

politicians <- list(
  list(
    id = 1L,
    name = "Barack",
    surname = "Obama",
    dob = "1961-08-04",
    n_children = 2,
    parents = list(
      mother = "Ann Dunham",
      father = "Barack Obama Sr."
    ),
    spouses = list("Michelle Robinson"),
    offices = list(
      list(
        name = "President of the United States",
        start = "2009-01-20"
      ),
      list(
        name = "United States Senator from Illinois",
        start = "2005-01-03"
      )
    )
  ),
  list(
    id = 2L,
    name = "Boris",
    surname = "Johnson",
    dob = "1964-06-19",
    parents = list(
      father = "Stanley Johnson"
    ),
    spouses = list(
      "Allegra Mostyn-Owen",
      "Marina Wheeler"
    ),
    offices = list(
      list(
        name = "Prime Minister of the United Kingdom",
        start = "2019-07-24"
      ),
      list(
        name = "Leader of the Conservative Party",
        start = "2019-07-23"
      ),
      list(
        name = "Mayor of London",
        start = "2008-05-04"
      )
    )
  )
)

usethis::use_data(politicians, overwrite = TRUE)
