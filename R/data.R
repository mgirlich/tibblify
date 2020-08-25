#' Game of Thrones POV characters
#'
#' The data is from the [repurrrsive package](https://github.com/jennybc/repurrrsive).
#'
#' Info on the point-of-view (POV) characters from the first five books in the
#' Song of Ice and Fire series by George R. R. Martin. Retrieved from An API Of
#' Ice And Fire.
#'
#' @format A unnamed list with 30 components, each representing a POV character.
#'   Each character's component is a named list of length 18, containing
#'   information such as name, aliases, and house allegiances.
#'
#' @family Game of Thrones data and functions
#' @source <https://anapioficeandfire.com>
#' @examples
#' got_chars
#' str(lapply(got_chars, `[`, c("name", "culture")))
"got_chars"

#' Politicians
#'
#' A dataset containing some basic information about some politicians.
#'
#' @format A list of lists.
"politicians"
