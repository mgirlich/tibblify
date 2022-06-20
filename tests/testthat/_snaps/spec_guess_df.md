# gives nice errors

    Code
      (expect_error(spec_guess_df(list(a = 1))))
    Output
      <error/rlang_error>
      Error in `spec_guess_df()`:
      ! `x` must be a <data.frame>. Instead, it is a list.
      i Did you want to use `spec_guess_list()()` instead?
    Code
      (expect_error(spec_guess_df(1:3)))
    Output
      <error/rlang_error>
      Error in `spec_guess_df()`:
      ! `x` must be a <data.frame>. Instead, it is a <integer>.

