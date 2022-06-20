# gives nice errors

    Code
      (expect_error(spec_guess_object(tibble(a = 1))))
    Output
      <error/rlang_error>
      Error in `spec_guess_object()`:
      ! `x` must not be a dataframe.
      i Did you want to use `spec_guess_df()` instead?
    Code
      (expect_error(spec_guess_object(1:3)))
    Output
      <error/rlang_error>
      Error in `spec_guess_object()`:
      ! `x` must be a list. Instead, it is a <integer>.

