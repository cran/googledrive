#' Update an existing Drive file
#'
#' Update an existing Drive file id with new content ("media" in Drive
#' API-speak), new metadata, or both.  To create a new file or update existing,
#' depending on whether the Drive file already exists, see [drive_put()].
#'
#' @seealso Wraps the `files.update` endpoint:
#'   * <https://developers.google.com/drive/api/v3/reference/files/update>
#'
#' This function supports media upload:
#'   * <https://developers.google.com/drive/api/v3/manage-uploads>
#'
#' @template file-singular
#' @template media
#' @template dots-metadata
#' @template verbose
#'
#' @eval return_dribble()
#' @export
#'
#' @examplesIf drive_has_token()
#' # Create a new file, so we can update it
#' x <- drive_example_remote("chicken.csv") %>%
#'   drive_cp()
#'
#' # Update the file with new media
#' x <- x %>%
#'   drive_update(drive_example_local("chicken.txt"))
#'
#' # Update the file with new metadata.
#' # Notice here `name` is not an argument of `drive_update()`, we are passing
#' # this to the API via the `...``
#' x <- x %>%
#'   drive_update(name = "CHICKENS!")
#'
#' # Update the file with new media AND new metadata
#' x <- x %>%
#'   drive_update(
#'     drive_example_local("chicken.txt"),
#'     name = "chicken-poem-again.txt"
#'   )
#'
#' # Clean up
#' drive_rm(x)
drive_update <- function(file,
                         media = NULL,
                         ...,
                         verbose = deprecated()) {
  warn_for_verbose(verbose)
  if ((!is.null(media)) && (!file.exists(media))) {
    drive_abort(c(
      "No file exists at the local {.arg media} path:",
      bulletize(gargle_map_cli(media, "{.path <<x>>}"), bullet = "x")
    ))
  }

  file <- as_dribble(file)
  file <- confirm_single_file(file)

  meta <- toCamel(list2(...))

  if (is.null(media) && length(meta) == 0) {
    drive_bullets(c(
      "!" = "No updates specified."
    ))
    return(invisible(file))
  }

  meta[["fields"]] <- meta[["fields"]] %||% "*"

  if (is.null(media)) {
    out <- drive_update_metadata(file, meta)
  } else {
    if (length(meta) == 0) {
      out <- drive_update_media(file, media)
    } else {
      media <- enc2utf8(media)
      out <- drive_update_multipart(file, media, meta)
    }
  }

  drive_bullets(c("File updated:", bulletize(gargle_map_cli(out))))

  invisible(out)
}

## currently this can never be called, because we always send fields
drive_update_media <- function(file, media) {
  request <- request_generate(
    endpoint = "drive.files.update.media",
    params = list(
      fileId = file$id,
      uploadType = "media",
      fields = "*"
    )
  )

  ## media uploads have unique body situations, so customizing here.
  request$body <- httr::upload_file(path = media)
  response <- request_make(request)
  as_dribble(list(gargle::response_process(response)))
}

drive_update_metadata <- function(file, meta) {
  params <- meta %||% list()
  params$fileId <- file$id
  request <- request_generate(
    endpoint = "drive.files.update",
    params = params
  )
  response <- request_make(request)
  as_dribble(list(gargle::response_process(response)))
}

drive_update_multipart <- function(file, media, meta) {
  # We include the metadata here even though it's overwritten below,
  # so that request_generate() still validates it.
  params <- meta %||% list()
  params$fileId <- file$id
  params$uploadType <- "multipart"
  request <- request_generate(
    endpoint = "drive.files.update.media",
    params = params
  )
  meta_file <- withr::local_file(
    tempfile("drive-update-meta", fileext = ".json")
  )
  write_utf8(jsonlite::toJSON(meta), meta_file)
  ## media uploads have unique body situations, so customizing here.
  request$body <- list(
    metadata = httr::upload_file(
      path = meta_file,
      type = "application/json; charset=UTF-8"
    ),
    media = httr::upload_file(path = media)
  )
  response <- request_make(request, encode = "multipart")
  as_dribble(list(gargle::response_process(response)))
}
