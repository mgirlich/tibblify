# checks input

    Code
      (expect_error(untibblify(1:3)))
    Output
      <error/rlang_error>
      Error in `untibblify()`:
      ! `x` must be a list. Instead, it is a <integer>.
    Code
      (expect_error(untibblify(new_rational(1, 1:3))))
    Output
      <error/rlang_error>
      Error in `untibblify()`:
      ! `x` must be a list. Instead, it is a <vctrs_rational>.

