% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/deprecated.R
\name{googledrive-deprecated}
\alias{googledrive-deprecated}
\alias{drive_auth_config}
\alias{drive_oauth_app}
\alias{drive_example}
\title{Deprecated googledrive functions}
\usage{
drive_auth_config(active, app, path, api_key)

drive_oauth_app()

drive_example(path = NULL)
}
\arguments{
\item{app}{\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#deprecated}{\figure{lifecycle-deprecated.svg}{options: alt='[Deprecated]'}}}{\strong{[Deprecated]}} Replaced by the \code{client}
argument.}

\item{path}{JSON downloaded from \href{https://console.cloud.google.com}{Google Cloud Console}, containing a client id and
secret, in one of the forms supported for the \code{txt} argument of
\code{\link[jsonlite:fromJSON]{jsonlite::fromJSON()}} (typically, a file path or JSON string).}

\item{api_key}{API key.}
}
\description{
\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#deprecated}{\figure{lifecycle-deprecated.svg}{options: alt='[Deprecated]'}}}{\strong{[Deprecated]}}
}
\section{\code{drive_auth_config()}}{


This function is defunct.
\itemize{
\item Use \code{\link[=drive_auth_configure]{drive_auth_configure()}} to configure your own OAuth client or API key.
\item Use \code{\link[=drive_deauth]{drive_deauth()}} to go into a de-authorized state.
\item Use \code{\link[=drive_oauth_client]{drive_oauth_client()}} to retrieve a user-configured client, if it
exists.
\item Use \code{\link[=drive_api_key]{drive_api_key()}} to retrieve a user-configured API key, if it exists.
}
}

\section{\code{drive_oauth_app()}}{


In light of the new \code{\link[gargle:gargle_oauth_client_from_json]{gargle::gargle_oauth_client()}} constructor and class of
the same name, \code{drive_oauth_app()} is being replaced by
\code{\link[=drive_oauth_client]{drive_oauth_client()}}.
}

\section{\code{drive_example()}}{


This function is defunct. Access example files with \code{\link[=drive_examples_local]{drive_examples_local()}},
\code{\link[=drive_example_local]{drive_example_local()}}, \code{\link[=drive_examples_remote]{drive_examples_remote()}}, and
\code{\link[=drive_example_remote]{drive_example_remote()}}.
}

\keyword{internal}
