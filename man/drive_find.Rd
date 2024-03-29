% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/drive_find.R
\name{drive_find}
\alias{drive_find}
\title{Find files on Google Drive}
\usage{
drive_find(
  pattern = NULL,
  trashed = FALSE,
  type = NULL,
  n_max = Inf,
  shared_drive = NULL,
  corpus = NULL,
  ...,
  verbose = deprecated(),
  team_drive = deprecated()
)
}
\arguments{
\item{pattern}{Character. If provided, only the items whose names match this
regular expression are returned. This is implemented locally on the results
returned by the API.}

\item{trashed}{Logical. Whether to search files that are not in the trash
(\code{trashed = FALSE}, the default), only files that are in the trash
(\code{trashed = TRUE}), or to search regardless of trashed status (\code{trashed = NA}).}

\item{type}{Character. If provided, only files of this type will be returned.
Can be anything that \code{\link[=drive_mime_type]{drive_mime_type()}} knows how to handle. This is
processed by googledrive and sent as a query parameter.}

\item{n_max}{Integer. An upper bound on the number of items to return. This
applies to the results requested from the API, which may be further
filtered locally, via the \code{pattern} argument.}

\item{shared_drive}{Anything that identifies one specific shared drive: its
name, its id or URL marked with \code{\link[=as_id]{as_id()}}, or a \code{\link{dribble}}. The value
provided to \code{shared_drive} is pre-processed with \code{\link[=as_shared_drive]{as_shared_drive()}}. Read
more about \link[=shared_drives]{shared drives}.}

\item{corpus}{Character, specifying which collections of items to search.
Relevant to those who work with shared drives and/or Google Workspace
domains. If specified, must be one of \code{"user"}, \code{"drive"} (requires that
\code{shared_drive} also be specified), \code{"allDrives"}, or \code{"domain"}. Read more
about \link[=shared_drives]{shared drives}.}

\item{...}{Other parameters to pass along in the request. The most likely
candidate is \code{q}. See below and the API's
\href{https://developers.google.com/drive/api/v3/search-files}{Search for files and folders guide}.}

\item{verbose}{\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#deprecated}{\figure{lifecycle-deprecated.svg}{options: alt='[Deprecated]'}}}{\strong{[Deprecated]}} This logical argument to
individual googledrive functions is deprecated. To globally suppress
googledrive messaging, use \code{options(googledrive_quiet = TRUE)} (the default
behaviour is to emit informational messages). To suppress messaging in a
more limited way, use the helpers \code{\link[=local_drive_quiet]{local_drive_quiet()}} or
\code{\link[=with_drive_quiet]{with_drive_quiet()}}.}

\item{team_drive}{\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#deprecated}{\figure{lifecycle-deprecated.svg}{options: alt='[Deprecated]'}}}{\strong{[Deprecated]}} Google Drive and the
Drive API have replaced Team Drives with shared drives.}
}
\value{
An object of class \code{\link{dribble}}, a tibble with one row per file.
}
\description{
This is the closest googledrive function to what you can do at
\url{https://drive.google.com}: by default, you just get a listing of your files.
You can also search in various ways, e.g., filter by file type or ownership
or work with \link[=shared_drives]{shared drives}. This is a very powerful
function. Together with the more specific \code{\link[=drive_get]{drive_get()}}, this is the main way
to identify files to target for downstream work. If you know you want to
search within a specific folder or shared drive, use \code{\link[=drive_ls]{drive_ls()}}.
}
\section{File type}{


The \code{type} argument is pre-processed with \code{\link[=drive_mime_type]{drive_mime_type()}}, so you can
use a few shortcuts and file extensions, in addition to full-blown MIME
types. googledrive forms a search clause to pass to \code{q}.
}

\section{Search parameters}{


Do advanced search on file properties by providing search clauses to the
\code{q} parameter that is passed to the API via \code{...}. Multiple \code{q} clauses or
vector-valued \code{q} are combined via 'and'.
}

\section{Trash}{


By default, \code{drive_find()} sets \code{trashed = FALSE} and does not include
files in the trash. Literally, it adds \code{q = "trashed = false"} to the
query. To search \emph{only} the trash, set \code{trashed = TRUE}. To see files
regardless of trash status, set \code{trashed = NA}, which adds
\code{q = "(trashed = true or trashed = false)"} to the query.
}

\section{Sort order}{


By default, \code{drive_find()} sends \code{orderBy = "recency desc"}, so the top
files in your result have high "recency" (whatever that means). To suppress
sending \code{orderBy} at all, do \code{drive_find(orderBy = NULL)}. The \code{orderBy}
parameter accepts sort keys in addition to \code{recency}, which are documented
in the \href{https://developers.google.com/drive/api/v3/reference/files/list}{\code{files.list} endpoint}.
googledrive translates a snake_case specification of \code{order_by} into the
lowerCamel form, \code{orderBy}.
}

\section{Shared drives and domains}{


If you work with shared drives and/or Google Workspace, you can apply your
search query to collections of items beyond those associated with "My
Drive". Use the \code{shared_drive} or \code{corpus} arguments to control this.
Read more about \link[=shared_drives]{shared drives}.
}

\examples{
\dontrun{
# list "My Drive" w/o regard for folder hierarchy
drive_find()

# filter for folders, the easy way and the hard way
drive_find(type = "folder")
drive_find(q = "mimeType = 'application/vnd.google-apps.folder'")

# filter for Google Sheets, the easy way and the hard way
drive_find(type = "spreadsheet")
drive_find(q = "mimeType='application/vnd.google-apps.spreadsheet'")

# files whose names match a regex
# the local, general, sometimes-slow-to-execute version
drive_find(pattern = "ick")
# the server-side, executes-faster version
# NOTE: works only for a pattern at the beginning of file name
drive_find(q = "name contains 'chick'")

# search for files located directly in your root folder
drive_find(q = "'root' in parents")
# FYI: this is equivalent to
drive_ls("~/")

# control page size or cap the number of files returned
drive_find(pageSize = 50)
# all params passed through `...` can be camelCase or snake_case
drive_find(page_size = 50)
drive_find(n_max = 58)
drive_find(page_size = 5, n_max = 15)

# various ways to specify q search clauses
# multiple q's
drive_find(
  q = "name contains 'TEST'",
  q = "modifiedTime > '2020-07-21T12:00:00'"
)
# vector q
drive_find(q = c("starred = true", "visibility = 'anyoneWithLink'"))

# default `trashed = FALSE` excludes files in the trash
# `trashed = TRUE` consults ONLY file in the trash
drive_find(trashed = TRUE)
# `trashed = NA` disregards trash status completely
drive_find(trashed = NA)

# suppress the default sorting on recency
drive_find(order_by = NULL, n_max = 5)

# sort on various keys
drive_find(order_by = "modifiedByMeTime", n_max = 5)
# request descending order
drive_find(order_by = "quotaBytesUsed desc", n_max = 5)
}

}
\seealso{
Wraps the \code{files.list} endpoint:
\itemize{
\item \url{https://developers.google.com/drive/api/v3/reference/files/list}
}

Helpful resource for forming your own queries:
\itemize{
\item \url{https://developers.google.com/drive/api/v3/search-files}
}
}
