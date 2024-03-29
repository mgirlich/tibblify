% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/nest-tree.R
\name{nest_tree}
\alias{nest_tree}
\title{Convert a data frame to a tree}
\usage{
nest_tree(data, id_col, parent_col, children_to)
}
\arguments{
\item{data}{A data frame.}

\item{id_col}{Id column. The values must be unique and non-missing.}

\item{parent_col}{Parent column. Each value must either be missing (for the
root elements) or appear in the \code{id_col} column.}

\item{children_to}{Name of the column the children should be put.}
}
\value{
A tree like data frame.
}
\description{
Convert a data frame to a tree
}
\examples{
df <- tibble::tibble(
  id = 1:5,
  x = letters[1:5],
  parent = c(NA, NA, 1L, 2L, 4L)
)
out <- nest_tree(df, id, parent, "children")
out

out$children
out$children[[2]]$children
}
