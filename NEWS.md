# tibblify 0.2.0

Major rewrite of the tibblify package with lots of benefits:

* `tibblify()` is now implemented in C and therefore way faster.

* Support of column major format.

* Support for vectors as scalar lists and objects.

* Specification functions have been renamed
  * `lcols()` to `tspec_df()`
  * new specs `tspec_object()` and `tspec_row()`
  * `lcol_int()` to `tib_int()` etc

* `tspec_df()` gains an argument `.names_to` to store the names of a recordlist
  in a column.

* Added `untibblify()` to turn a tibble into a nested list, i.e. to reverse the action fo `tibblify()`.

* Added `spec_combine()` to combine multiple specifications.

* Added argument `unspecified` to `tibblify()` to control how to handle unspecified
  fields.

* Many bugfixes.  

# tibblify 0.1.0

* First CRAN release.
