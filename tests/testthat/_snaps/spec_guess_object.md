# gives nice errors

    Code
      (expect_error(guess_tspec_object(tibble(a = 1))))
    Output
      <error/rlang_error>
      Error in `guess_tspec_object()`:
      ! `x` must not be a dataframe.
      i Did you want to use `guess_tspec_df()` instead?
    Code
      (expect_error(guess_tspec_object(1:3)))
    Output
      <error/rlang_error>
      Error in `guess_tspec_object()`:
      ! `x` must be a list, not an integer vector.

---

    Code
      (expect_error(guess_tspec_object(list(1, a = 1))))
    Output
      <error/rlang_error>
      Error in `guess_tspec_object()`:
      ! `x` must be fully named.
    Code
      (expect_error(guess_tspec_object(list(a = 1, a = 1))))
    Output
      <error/rlang_error>
      Error in `guess_tspec_object()`:
      ! Names of `x` must be unique.

