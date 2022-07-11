# gives nice errors

    Code
      (expect_error(tspec_guess_object(tibble(a = 1))))
    Output
      <error/rlang_error>
      Error in `tspec_guess_object()`:
      ! `x` must not be a dataframe.
      i Did you want to use `tspec_guess_df()` instead?
    Code
      (expect_error(tspec_guess_object(1:3)))
    Output
      <error/rlang_error>
      Error in `tspec_guess_object()`:
      ! `x` must be a list. Instead, it is a <integer>.

---

    Code
      (expect_error(tspec_guess_object(list(1, a = 1))))
    Output
      <error/rlang_error>
      Error in `tspec_guess_object()`:
      ! `x` must be fully named.
    Code
      (expect_error(tspec_guess_object(list(a = 1, a = 1))))
    Output
      <error/rlang_error>
      Error in `tspec_guess_object()`:
      ! Names of `x` must be unique.

