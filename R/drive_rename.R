#' Rename a Drive file
#'
#' This is a wrapper for [`drive_mv()`] that only renames a file.
#' If you would like to rename AND move the file, see [`drive_mv()`].
#'
#' @template file-singular
#' @param name Character. Name you would like the file to have.
#' @template overwrite
#' @template verbose
#'
#' @eval return_dribble()
#'
#' @examplesIf drive_has_token()
#' # Create a file to rename
#' file <- drive_create("file-to-rename")
#'
#' # Rename it
#' file <- drive_rename(file, name = "renamed-file")
#'
#' # `overwrite = FALSE` errors if something already exists at target filepath
#' # THIS WILL ERROR!
#' drive_create("name-squatter-rename")
#' drive_rename(file, name = "name-squatter-rename", overwrite = FALSE)
#'
#' # `overwrite = TRUE` moves the existing item to trash, then proceeds
#' file <- drive_rename(file, name = "name-squatter-rename", overwrite = TRUE)
#'
#' # Clean up
#' drive_rm(file)
#' @export
drive_rename <- function(file,
                         name = NULL,
                         overwrite = NA,
                         verbose = deprecated()) {
  warn_for_verbose(verbose)
  drive_mv(file = file, name = name, overwrite = overwrite)
}
