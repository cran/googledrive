#' Create a Drive folder
#'
#' Creates a new Drive folder. To update the metadata of an existing Drive file,
#' including a folder, use [drive_update()].
#'
#' @seealso Wraps the `files.create` endpoint:
#'   * <https://developers.google.com/drive/api/v3/reference/files/create>
#'
#' @param name Name for the new folder or, optionally, a path that specifies
#'   an existing parent folder, as well as the new name.
#' @eval param_path_known_parent("folder")
#' @inheritParams drive_create
#'
#' @eval return_dribble()
#' @export
#' @examplesIf drive_has_token()
#' # Create folder named 'ghi', then another below named it 'jkl' and star it
#' ghi <- drive_mkdir("ghi")
#' jkl <- drive_mkdir("ghi/jkl", starred = TRUE)
#'
#' # is 'jkl' really starred? YES
#' purrr::pluck(jkl, "drive_resource", 1, "starred")
#'
#' # Another way to create folder 'mno' in folder 'ghi'
#' drive_mkdir("mno", path = "ghi")
#'
#' # Yet another way to create a folder named 'pqr' in folder 'ghi',
#' # this time with parent folder stored in a dribble,
#' # and setting the new folder's description
#' pqr <- drive_mkdir("pqr", path = ghi, description = "I am a folder")
#'
#' # Did we really set the description? YES
#' purrr::pluck(pqr, "drive_resource", 1, "description")
#'
#' # `overwrite = FALSE` errors if something already exists at target filepath
#' # THIS WILL ERROR!
#' drive_create("name-squatter-mkdir", path = ghi)
#' drive_mkdir("name-squatter-mkdir", path = ghi, overwrite = FALSE)
#'
#' # `overwrite = TRUE` moves the existing item to trash, then proceeds
#' drive_mkdir("name-squatter-mkdir", path = ghi, overwrite = TRUE)
#'
#' # list everything inside 'ghi'
#' drive_ls("ghi")
#'
#' # Clean up
#' drive_rm(ghi)
drive_mkdir <- function(name,
                        path = NULL,
                        ...,
                        overwrite = NA,
                        verbose = deprecated()) {
  warn_for_verbose(verbose)

  drive_create(
    name = name,
    path = path,
    type = "application/vnd.google-apps.folder",
    ...,
    overwrite = overwrite
  )
}
