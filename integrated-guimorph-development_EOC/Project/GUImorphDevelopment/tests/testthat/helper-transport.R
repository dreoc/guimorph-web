# Helpers for the transport suite (test-transport.R). testthat auto-sources
# helper-*.R before the tests, so these are in scope without an explicit source.
# No test_that blocks live here.

# curl is Suggests-only; the byte-integrity / guard tests need it to GET the
# served file. Skip cleanly (not fail) when it is unavailable.
skip_if_no_curl <- function() testthat::skip_if_not_installed("curl")

# Free-port probe stub factory: returns a probe reporting every port free except
# those in `busy`. Lets the port-fallback test assert walk-forward ordering
# without binding a real socket.
gmw_probe_stub <- function(busy = integer()) {
  force(busy)
  function(p) !(as.integer(p) %in% as.integer(busy))
}

# Parse the token segment out of a served URL (http://127.0.0.1:<port>/<token>/).
gmw_url_token <- function(url) {
  sub("^http://127\\.0\\.0\\.1:[0-9]+/(.+)/$", "\\1", url)
}

# Parse the origin (scheme://host:port) out of a served URL, dropping the token.
gmw_url_origin <- function(url) {
  sub("^(http://127\\.0\\.0\\.1:[0-9]+)/.*$", "\\1", url)
}

# GET a URL with a bounded timeout, returning the curl response, or NULL if the
# request errors or times out. httpuv's staticPaths app has no call() handler, so
# an unmatched path (the guard case) is never answered -- without a timeout curl
# would block forever. A NULL here means "the server did not serve it", which is
# exactly the refusal the guard test asserts.
gmw_try_fetch <- function(url, timeout = 5) {
  if (!requireNamespace("curl", quietly = TRUE)) return(NULL)
  h <- curl::new_handle()
  curl::handle_setopt(h, timeout_ms = as.integer(timeout * 1000),
                      connecttimeout_ms = as.integer(min(timeout, 10) * 1000))
  tryCatch(curl::curl_fetch_memory(url, handle = h), error = function(e) NULL)
}
