#' Make a request for the Google Drive v3 API
#'
#' Low-level functions to execute one or more Drive API requests and, perhaps,
#' process the response(s). Most users should, instead, use higher-level
#' wrappers that facilitate common tasks, such as uploading or downloading Drive
#' files. The functions here are intended for internal use and for programming
#' around the Drive API. Three functions are documented here:
#'   * `request_make()` does the bare minimum: calls [gargle::request_make()],
#'     only adding the googledrive user agent. Typically the input is created
#'     with [request_generate()] and the output is processed with
#'     [gargle::response_process()].
#'   * `do_request()` is simply
#'     `gargle::response_process(request_make(x, ...))`. It exists only because
#'     we had to make `do_paginated_request()` and it felt weird to not make the
#'     equivalent for a single request.
#'   * `do_paginated_request()` executes the input request **with page
#'     traversal**. It is impossible to separate paginated requests into a "make
#'     request" step and a "process request" step, because the token for the
#'     next page must be extracted from the content of the current page.
#'     Therefore this function does both and returns a list of processed
#'     responses, one per page.
#'
#' @param x List, holding the components for an HTTP request, presumably created
#'   with [request_generate()] Should contain the `method`, `url`, `body`,
#'   and `token`.
#' @param ... Optional arguments passed through to the HTTP method.
#' @template verbose
#'
#' @return `request_make()`: Object of class `response` from [httr].
#' @export
#' @family low-level API functions
request_make <- function(x, ...) {
  gargle::request_retry(x, ..., user_agent = drive_ua())
}

#' @rdname request_make
#' @export
#' @return `do_request()`: List representing the content returned by a single
#'   request.
do_request <- function(x, ...) {
  gargle::response_process(request_make(x, ...))
}

#' @rdname request_make
#' @param n_max Maximum number of items to return. Defaults to `Inf`, i.e. there
#'   is no limit and we keep making requests until we get all items.
#' @param n Function that computes the number of items in one response or page.
#'   The default function always returns `1` and therefore treats each page as
#'   an item. If you know more about the structure of the response, you can
#'   pass another function to count and threshhold, for example, the number of
#'   files or comments.
#' @export
#' @return `do_paginated_request()`: List of lists, representing the returned
#'   content, one component per page.
#' @examples
#' \dontrun{
#' # build a request for an endpoint that is:
#' #   * paginated
#' #   * NOT privileged in googledrive, i.e. not covered by request_generate()
#' # "comments" are a great example
#' # https://developers.google.com/drive/v3/reference/comments
#' #
#' # Practice with a target file with > 2 comments
#' # Note that we request 2 items (comments) per page
#' req <- gargle::request_build(
#'   path = "drive/v3/files/{fileId}/comments",
#'   method = "GET",
#'   params = list(
#'     fileId = "your-file-id-goes-here",
#'     fields = "*",
#'     pageSize = 2
#'   ),
#'   token = googledrive::drive_token()
#' )
#' # make the paginated request, but cap it at 1 page
#' # should get back exactly two comments
#' do_paginated_request(req, n_max = 1)
#' }
do_paginated_request <- function(x,
                                 ...,
                                 n_max = Inf,
                                 n = function(res) 1,
                                 verbose = deprecated()) {
  warn_for_verbose(verbose)

  ## when traversing pages, you can't cleanly separate the task into
  ## request_make() and gargle::response_process(), because you need to process
  ## response / page i to get the pageToken for request / page i + 1
  ## so this function does both
  stopifnot(identical(x$method, "GET"))

  ## if fields does not exist yet, you will need something to prepend
  ## "nextPageToken" to ... "all fields" seems like best (only?) default choice
  x$query$fields <- x$query$fields %||% "*"
  if (!grepl("nextPageToken", x$query$fields)) {
    x$query$fields <- glue("nextPageToken,{x$query$fields}")
  }

  responses <- list()
  i <- 1
  total <- 0
  # TODO: do I have anything to say here at the beginning?
  # what's a non-jargon-y and general way to say:
  # "we're hitting a paginated endpoint and we're working with pageSize n"
  st <- show_status()
  if (st) sb <- cli::cli_status(msg = character())
  repeat {
    page <- request_make(x, ...)
    responses[[i]] <- gargle::response_process(page)
    x$query$pageToken <- responses[[i]]$nextPageToken
    x$url <- httr::modify_url(x$url, query = x$query)
    # TODO: presumably this might need some generalization when this moves
    # to gargle (how we determine how much 'stuff' we've seen and how we
    # talk about it in the status bar)
    # TODO: need to do something re: non-interactive work, e.g. Rmd
    total <- total + n(responses[[i]])
    if (is.null(x$query$pageToken) || total >= n_max) {
      break
    }
    if (st) {
      cli::cli_status_update(
        id = sb,
        "{cli::symbol$arrow_right} Files retrieved so far: {total}"
      )
    }
    i <- i + 1
  }

  responses
}

show_status <- function() {
  is_interactive() && is_false(getOption("googledrive_quiet", FALSE))
}

drive_ua <- function() {
  httr::user_agent(paste0(
    "googledrive/", utils::packageVersion("googledrive"), " ",
    "(GPN:RStudio; )", " ",
    "gargle/", utils::packageVersion("gargle"), " ",
    "httr/", utils::packageVersion("httr")
  ))
}
