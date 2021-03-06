#' Get info on current user
#'
#' Reveals information about the user associated with the current token. This is
#' a thin wrapper around [drive_about()] that just extracts the most useful
#' information (the information on current user) and prints it nicely.
#'
#' @seealso Wraps the `about.get` endpoint:
#'   * <https://developers.google.com/drive/api/v3/reference/about/get>
#'
#' @template verbose
#'
#' @return A list of class `drive_user`.
#' @export
#' @examplesIf drive_has_token()
#' drive_user()
#'
#' # more info is returned than is printed
#' user <- drive_user()
#' str(user)
drive_user <- function(verbose = deprecated()) {
  warn_for_verbose(verbose)

  if (!drive_has_token()) {
    drive_bullets(c(
      "i" = "Not logged in as any specific Google user."
    ))
    return(invisible())
  }
  about <- drive_about()
  structure(about[["user"]], class = c("drive_user", "list"))
}

#' @export
format.drive_user <- function(x, ...) {
  cli::cli_format_method(
    drive_bullets(c(
      "Logged in as:",
      "*" = "displayName: {.field {x[['displayName']]}}",
      "*" = "emailAddress: {.email {x[['emailAddress']]}}"
    ))
  )
}

#' @export
print.drive_user <- function(x, ...) {
  cli::cat_line(format(x, ...))
  invisible(x)
}
