# tibblify (development version)

* New `parse_openapi_spec()` and `parse_openapi_schema()` to convert an
  OpenAPI specification to a tibblify specification.

* Fix ptype of a `tib_vector()` inside a `tib_df()`.

* New `unpack_tspec()` to unpack the elements of `tib_row()` fields (#165).

* Improved printing of lists parsed with `tspec_object()`.

# tibblify 0.3.0

* In column major format all fields are required.

* Fixed a memory leak.

* `tib_vector()` is now uses less memory and is faster.

* `tspec_*()`, `tib_df()`, and `tib_row()` now discard `NULL` in `...`. This
  makes it easier to add a field conditionally with, for example
  `tspec_df(if (x) tib_int("a"))`.

* `tib_variant()` and `tib_vector()` give you more control for transforming:

  * `transform` is now applied to the whole vector.
  
  * There is a new `elt_transform` argument that is applied to every element.

* New `tspec_recursive()` and `tib_recursive()` to parse tree like structure,
  e.g. a directory structure with its children.

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

* Added `untibblify()` to turn a tibble into a nested list, i.e. to reverse the action of `tibblify()`.

* Added `spec_combine()` to combine multiple specifications.

* Added argument `unspecified` to `tibblify()` to control how to handle unspecified
  fields.

* Many bugfixes.  

# tibblify 0.1.0

* First CRAN release.
