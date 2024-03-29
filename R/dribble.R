#' dribble object
#'
#' @description googledrive stores the metadata for one or more Drive files or
#'   shared drives as a `dribble`. It is a "Drive
#'   [tibble][tibble::tibble-package]" with one row per file or shared drive
#'   and, at a minimum, these columns:
#'   * `name`: a character column containing file or shared drive names
#'   * `id`: a character column of file or shared drive ids
#'   * `drive_resource`: a list-column, each element of which is either a
#'   [Files resource](https://developers.google.com/drive/api/v3/reference/files#resource-representations)
#'   or a [Drives resource](https://developers.google.com/drive/api/v3/reference/drives#resource-representations)
#'   object. Note there is no guarantee that all documented fields are always
#'   present. We do check if the `kind` field is present and equal to one of
#'   `drive#file` or `drive#drive`.
#'
#' @description The `dribble` format is handy because it exposes the file name,
#'   which is good for humans, but keeps it bundled with the file's unique id
#'   and other metadata, which are needed for API calls.
#'
#' @description In general, the `dribble` class will be retained even after
#'   manipulation, as long as the required variables are present and of the
#'   correct type. This works best for manipulations via the dplyr and vctrs
#'   packages.
#'
#' @name dribble
#' @seealso [as_dribble()]
NULL

# implementing dribble as advised here:
# https://github.com/hadley/adv-r/blob/master/S3.Rmd

new_dribble <- function(x) {
  # new_tibble0() strips attributes
  out <- structure(
    new_tibble0(x),
    class = c("dribble", "tbl_df", "tbl", "data.frame")
  )
  out$id <- new_drive_id(unclass(out$id))
  out
}

validate_dribble <- function(x) {
  stopifnot(inherits(x, "dribble"))

  if (!has_dribble_cols(x)) {
    missing_cols <- setdiff(dribble_cols, colnames(x))
    drive_abort(c(
      "Invalid {.cls dribble}. \\
       {cli::qty(length(missing_cols))}{?This/These} required column{?s} \\
       {?is/are} missing:",
      bulletize(gargle_map_cli(missing_cols, template = "{.code <<x>>}"))
    ))
  }

  if (!has_dribble_coltypes(x)) {
    mistyped_cols <- dribble_cols[!dribble_coltypes_ok(x)]
    drive_abort(c(
      "Invalid {.cls dribble}. \\
       {cli::qty(length(mistyped_cols))}{?This/These} column{?s} {?has/have} \\
       the wrong type:",
      bulletize(gargle_map_cli(mistyped_cols, template = "{.code <<x>>}"))
    ))
  }

  # TODO: should I make sure there are no NAs in the id column?
  # let's wait and see if we ever experience any harm from NOT checking this
  # also, that feels more like something to enforce by creating a proper
  # S3 vctr for Drive file ids and it might be odd to make NAs unacceptable

  if (!has_drive_resource(x)) {
    # \u00a0 is a nonbreaking space
    drive_abort(c(
      'Invalid {.cls dribble}. Can\'t confirm \\
       {.code kind\u00a0=\u00a0"drive#file"} or \\
       {.code kind\u00a0=\u00a0"drive#drive"} \\
       for all elements of the {.code drive_resource} column.'
    ))
  }
  x
}

dribble <- function(x = NULL) {
  x <- x %||%
    list(
      name = character(),
      id = character(),
      drive_resource = list()
    )
  validate_dribble(new_dribble(x))
}

#' @export
`[.dribble` <- function(x, i, j, drop = FALSE) {
  dribble_maybe_reconstruct(NextMethod())
}

#' @export
`names<-.dribble` <- function(x, value) {
  dribble_maybe_reconstruct(NextMethod())
}

#' @export
tbl_sum.dribble <- function(x) {
  orig <- NextMethod()
  c("A dribble" = unname(orig))
}

#' @export
as_tibble.dribble <- function(x, ...) {
  as_tibble(new_tibble0(x), ...)
}

dribble_cols <- c("name", "id", "drive_resource")

has_dribble_cols <- function(x) {
  all(dribble_cols %in% colnames(x))
}

dribble_coltypes_ok <- function(x) {
  c(
    name = is.character(x$name),
    id = is.character(x$id),
    drive_resource = inherits(x$drive_resource, "list")
  )
}

has_dribble_coltypes <- function(x) {
  all(dribble_coltypes_ok(x))
}

id_can_be_drive_id <- function(x) {
  all(is_valid_drive_id(x))
}

has_drive_resource <- function(x) {
  kind <- map_chr(x$drive_resource, "kind", .default = NA_character_)
  # TODO: remove `drive#teamDrive` here, when possible
  all(!is.na(kind) & kind %in% c("drive#file", "drive#drive", "drive#teamDrive"))
}

#' Coerce to a `dribble`
#'
#' @description
#' Converts various representations of Google Drive files into a [`dribble`],
#' the object used by googledrive to hold Drive file metadata. Files can be
#' specified via:
#'   * File path. File name is an important special case.
#'   * File id. Mark with [as_id()] to distinguish from file path.
#'   * Data frame or [`dribble`]. Once you've successfully used googledrive to
#'     identify the files of interest, you'll have a [`dribble`]. Pass it into
#'     downstream functions.
#'   * List representing [Files resource](https://developers.google.com/drive/api/v3/reference/files)
#'     objects. Mostly for internal use.
#'
#' This is a generic function.
#'
#' For maximum clarity, get your files into a [`dribble`] (or capture file id)
#' as early as possible. When specifying via path, it's best to include the
#' trailing slash when you're targeting a folder. If you want the folder `foo`,
#' say `foo/`, not `foo`.
#'
#' Some functions, such as [drive_cp()], [drive_mkdir()], [drive_mv()], and
#' [drive_upload()], can accept the new file or folder name as the last part of
#' `path`, when `name` is not given. But if you say `a/b/c` (no trailing slash)
#' and a folder `a/b/c/` already exists, it's unclear what you want. A file
#' named `c` in `a/b/` or a file with default name in `a/b/c/`? You get an
#' error and must make your intent clear.
#'
#' @param x A vector of Drive file paths, a vector of file ids marked
#'   with [as_id()], a list of Files Resource objects, or a suitable data
#'   frame.
#' @param ... Other arguments passed down to methods. (Not used.)
#' @export
#' @examplesIf drive_has_token()
#' # create some files for us to re-discover by name or filepath
#' alfa <- drive_create("alfa", type = "folder")
#' bravo <- drive_create("bravo", path = alfa)
#'
#' # as_dribble() can work with file names or paths
#' as_dribble("alfa")
#' as_dribble("bravo")
#' as_dribble("alfa/bravo")
#' as_dribble(c("alfa", "alfa/bravo"))
#'
#' # specify the file id (substitute a real file id of your own!)
#' # as_dribble(as_id("0B0Gh-SuuA2nTOGZVTXZTREgwZ2M"))
#'
#' # Clean up
#' drive_find("alfa") %>% drive_rm()
as_dribble <- function(x, ...) UseMethod("as_dribble")

#' @export
as_dribble.default <- function(x, ...) {
  drive_abort("
    Don't know how to coerce an object of class {.cls {class(x)}} into \\
    a {.cls dribble}.")
}

#' @export
as_dribble.NULL <- function(x, ...) dribble()

#' @export
as_dribble.character <- function(x, ...) {
  with_drive_quiet(drive_get(path = x))
}

#' @export
as_dribble.drive_id <- function(x, ...) drive_get(id = x)

#' @export
as_dribble.data.frame <- function(x, ...) validate_dribble(new_dribble(x))

#' @export
as_dribble.list <- function(x, ...) {
  if (length(x) == 0) {
    return(dribble())
  }

  required_nms <- c("name", "id", "kind")
  stopifnot(map_lgl(x, ~ all(required_nms %in% names(.x))))

  as_dribble(
    tibble(
      name = map_chr(x, "name"),
      id = map_chr(x, "id"),
      drive_resource = x
    )
  )
}

# used across several functions that create a file or modify "parentage"
# processes a putative parent folder or shared drive
as_parent <- function(d) {
  in_var <- deparse(substitute(d))
  if (is_path(d)) {
    d <- append_slash(d)
  }
  d <- as_dribble(d)
  # wording chosen to work for folder and shared drive
  invalid_parent <- "Parent specified via {.arg {in_var}} is invalid:"
  if (no_file(d)) {
    drive_abort(c(invalid_parent, x = "Does not exist."))
  }
  if (!single_file(d)) {
    drive_abort(c(
      invalid_parent,
      x = "Doesn't uniquely identify exactly one folder or shared drive."
    ))
  }
  if (is_folder_shortcut(d)) {
    drive_bullets(c(
      i = "Parent specified via {.arg {in_var}} is a shortcut; resolving to \\
           its target folder"
    ))
    d <- shortcut_resolve(d)
  }
  if (!is_parental(d)) {
    drive_abort(c(
      invalid_parent,
      x = "Is neither a folder nor a shared drive."
    ))
  }
  d
}

#' Check facts about a dribble
#'
#' Sometimes you need to check things about a [`dribble`]` or about the files it
#' represents, such as:
#'   * Is it even a dribble?
#'   * Size: Does the dribble hold exactly one file? At least one file? No file?
#'   * File type: Is this file a folder?
#'   * File ownership and access: Is it mine? Published? Shared?
#'
#' @name dribble-checks
#' @param d A [`dribble`].
#' @examplesIf drive_has_token()
#' ## most of us have multiple files or folders on Google Drive
#' d <- drive_find()
#' is_dribble(d)
#' no_file(d)
#' single_file(d)
#' some_files(d)
#'
#' # this will error
#' # confirm_single_file(d)
#'
#' confirm_some_files(d)
#' is_folder(d)
#' is_mine(d)
NULL

#' @export
#' @rdname dribble-checks
is_dribble <- function(d) {
  inherits(d, "dribble")
}

#' @export
#' @rdname dribble-checks
no_file <- function(d) {
  stopifnot(inherits(d, "dribble"))
  nrow(d) == 0
}

#' @export
#' @rdname dribble-checks
single_file <- function(d) {
  stopifnot(inherits(d, "dribble"))
  nrow(d) == 1
}

#' @export
#' @rdname dribble-checks
some_files <- function(d) {
  stopifnot(inherits(d, "dribble"))
  nrow(d) > 0
}

#' @export
#' @rdname dribble-checks
confirm_dribble <- function(d) {
  if (!is_dribble(d)) {
    drive_abort("Input is not a {.cls dribble}.")
  }
  d
}

#' @export
#' @rdname dribble-checks
confirm_single_file <- function(d) {
  in_var <- deparse(substitute(d))
  if (no_file(d)) {
    drive_abort("{.arg {in_var}} does not identify at least one Drive file.")
  }
  if (!single_file(d)) {
    drive_abort("{.arg {in_var}} identifies more than one Drive file.")
  }
  d
}

#' @export
#' @rdname dribble-checks
confirm_some_files <- function(d) {
  in_var <- deparse(substitute(d))
  if (no_file(d)) {
    drive_abort("{.arg {in_var}} does not identify at least one Drive file.")
  }
  d
}

#' @export
#' @rdname dribble-checks
is_folder <- function(d) {
  stopifnot(inherits(d, "dribble"))
  map_chr(d$drive_resource, "mimeType", .default = NA) ==
    "application/vnd.google-apps.folder"
}

#' @export
#' @rdname dribble-checks
is_shortcut <- function(d) {
  stopifnot(inherits(d, "dribble"))
  map_chr(d$drive_resource, "mimeType", .default = NA) ==
    "application/vnd.google-apps.shortcut"
}

#' @export
#' @rdname dribble-checks
is_folder_shortcut <- function(d) {
  stopifnot(inherits(d, "dribble"))
  is_shortcut(d) &
    (map_chr(
      d$drive_resource,
      c("shortcutDetails", "targetMimeType"),
      .default = ""
    ) == "application/vnd.google-apps.folder")
}

#' @export
#' @rdname dribble-checks
is_native <- function(d) {
  stopifnot(inherits(d, "dribble"))
  d <- promote(d, "mimeType")
  grepl("application/vnd.google-apps.", d$mimeType) & !is_folder(d)
}

#' @export
#' @rdname dribble-checks
is_parental <- function(d) {
  stopifnot(inherits(d, "dribble"))
  kind <- map_chr(d$drive_resource, "kind")
  mime_type <- map_chr(d$drive_resource, "mimeType", .default = "")
  # TODO: remove `drive#teamDrive` here, when possible
  kind == "drive#teamDrive" |
    kind == "drive#drive" |
    mime_type == "application/vnd.google-apps.folder"
}

#' @export
#' @rdname dribble-checks
## TO DO: do I need to do anything about shared drives here?
is_mine <- function(d) {
  stopifnot(inherits(d, "dribble"))
  map_lgl(d$drive_resource, list("owners", 1, "me"))
}

#' @export
#' @rdname dribble-checks
is_shared_drive <- function(d) {
  stopifnot(inherits(d, "dribble"))
  map_chr(d$drive_resource, "kind") == "drive#drive"
}
