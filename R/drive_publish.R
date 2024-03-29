#' Publish native Google files
#'
#' Publish (or un-publish) native Google files to the web. Native Google files
#' include Google Docs, Google Sheets, and Google Slides. The returned
#' [`dribble`] will have extra columns, `published` and `revisions_resource`.
#' Read more in [drive_reveal()].
#'
#' @seealso Wraps the `revisions.update` endpoint:
#'   * <https://developers.google.com/drive/api/v3/reference/revisions/update>
#'
#' @template file-plural
#' @param ... Name-value pairs to add to the API request body (see API docs
#' linked below for details). For `drive_publish()`, we include
#' `publishAuto = TRUE` and `publishedOutsideDomain = TRUE`, if user does not
#' specify other values.
#' @template verbose
#'
#' @eval return_dribble(extras = "There will be extra columns, `published` and
#'   `revisions_resource`.")
#' @export
#' @examplesIf drive_has_token()
#' # Create a file to publish
#' file <- drive_example_remote("chicken_sheet") %>%
#'   drive_cp()
#'
#' # Publish file
#' file <- drive_publish(file)
#' file$published
#'
#' # Unpublish file
#' file <- drive_unpublish(file)
#' file$published
#'
#' # Clean up
#' drive_rm(file)
drive_publish <- function(file, ..., verbose = deprecated()) {
  warn_for_verbose(verbose)
  drive_change_publish(file = file, publish = TRUE, ...)
}

#' @rdname drive_publish
#' @export
drive_unpublish <- function(file, ..., verbose = deprecated()) {
  warn_for_verbose(verbose)
  drive_change_publish(file = file, publish = FALSE, ...)
}

drive_change_publish <- function(file,
                                 publish = TRUE,
                                 ...) {
  file <- as_dribble(file)
  file <- confirm_some_files(file)

  type_ok <- is_native(file)
  if (!all(type_ok)) {
    file <- file[!type_ok, ]
    file <- promote(file, "mimeType")
    drive_abort(c(
      "Only native Google files can be published.",
      "{.arg file} includes {?a/} file{?s} \\
       with non-native MIME type{cli::qty(nrow(file))}",
      bulletize(gargle_map_cli(file, "{.drivepath <<name>>}: {.field <<mimeType>>}")),
      "i" = "You can use {.fun drive_share} to change a file's sharing \\
             permissions."
    ))
  }

  params <- toCamel(list2(...))
  params[["published"]] <- publish
  params[["publishAuto"]] <- params[["publishAuto"]] %||% TRUE
  params[["publishedOutsideDomain"]] <-
    params[["publishedOutsideDomain"]] %||% TRUE
  params[["revisionId"]] <- "head"
  params[["fields"]] <- "*"

  revision_resource <- map(
    file$id,
    change_publish_one,
    params = params
  )
  n <- nrow(file)
  drive_bullets(c(
    cli::pluralize(
      "{cli::qty(n)}File{?s} now {if (publish) '' else 'NOT '}published:"
    ),
    bulletize(gargle_map_cli(file))
  ))
  invisible(drive_reveal(file, "published"))
}

change_publish_one <- function(id, params) {
  params[["fileId"]] <- id
  request <- request_generate(
    endpoint = "drive.revisions.update",
    params = params
  )
  response <- request_make(request)
  gargle::response_process(response)
}

drive_reveal_published <- function(file) {
  confirm_dribble(file)
  revision_resource <- map(file$id, get_publish_one)
  file <- put_column(
    file,
    nm = "published",
    val = map_lgl(revision_resource, "published", .default = FALSE),
    .after = 1
  )
  put_column(
    file,
    nm = "revision_resource",
    val = revision_resource
  )
}

get_publish_one <- function(id) {
  request <- request_generate(
    endpoint = "drive.revisions.get",
    params = list(
      fileId = id,
      revisionId = "head",
      fields = "*"
    )
  )
  response <- request_make(request)
  ## folders generate a 403
  if (httr::status_code(response) == 403) {
    return(NULL)
  }
  gargle::response_process(response)
}
