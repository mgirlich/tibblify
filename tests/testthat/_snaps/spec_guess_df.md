# gives nice errors

    Code
      (expect_error(guess_tspec_df(list(a = 1))))
    Output
      <error/rlang_error>
      Error in `guess_tspec_df()`:
      ! `x` is a list but not a list of objects.
    Code
      (expect_error(guess_tspec_df(1:3)))
    Output
      <error/rlang_error>
      Error in `guess_tspec_df()`:
      ! Cannot guess the specification for type integer.

# inform about unspecified elements

    Code
      guess_tspec_df(tibble(lgl = NA), inform_unspecified = TRUE)
    Message
      The spec contains 1 unspecified field:
      * lgl
    Output
      tspec_df(
        tib_unspecified("lgl"),
      )

