#' Create an rgl compatibility shim package.
#'
#' The generated source package is named `rgl` and re-exports `rmetal`. Install
#' it into a library path that appears before legacy `rgl` when a dependent
#' package still has `import(rgl)`.
#'
#' @param path Destination directory for the shim package source.
#' @return The normalized path, invisibly.
create_rgl_compat_package <- function(path) {
  if (dir.exists(path) && length(list.files(path, all.files = TRUE,
                                           no.. = TRUE))) {
    stop("Destination already exists and is not empty: ", path, call. = FALSE)
  }
  dir.create(file.path(path, "R"), recursive = TRUE, showWarnings = FALSE)
  writeLines(c(
    "Package: rgl",
    "Title: RMetal Compatibility Shim for rgl Imports",
    "Version: 99.99.99",
    "Description: Re-exports rmetal for packages that still import rgl.",
    "License: MIT",
    "Encoding: UTF-8",
    "Depends: R (>= 4.2.0)",
    "Imports: rmetal"
  ), file.path(path, "DESCRIPTION"))
  writeLines(c("import(rmetal)", "exportPattern(\"^[^.]\")"),
             file.path(path, "NAMESPACE"))
  writeLines(c(
    ".rmetal_exports <- getNamespaceExports(\"rmetal\")",
    "for (nm in .rmetal_exports) {",
    "  assign(nm, getExportedValue(\"rmetal\", nm), envir = environment())",
    "}",
    "rm(.rmetal_exports, nm)"
  ), file.path(path, "R", "exports.R"))
  invisible(normalizePath(path, mustWork = FALSE))
}

#' Patch an R package to import rmetal instead of rgl.
#'
#' This helper edits `DESCRIPTION`, `NAMESPACE`, and common package source
#' files, creating timestamped backups before edits.
#'
#' @param path Package source directory.
#' @return Invisibly returns the package path.
use_rmetal_in_package <- function(path) {
  desc <- file.path(path, "DESCRIPTION")
  ns <- file.path(path, "NAMESPACE")
  if (!file.exists(desc) || !file.exists(ns)) {
    stop("Expected DESCRIPTION and NAMESPACE under: ", path, call. = FALSE)
  }
  stamp <- format(Sys.time(), "%Y%m%d%H%M%S")
  file.copy(desc, paste0(desc, ".bak-", stamp), overwrite = FALSE)
  file.copy(ns, paste0(ns, ".bak-", stamp), overwrite = FALSE)

  d <- readLines(desc, warn = FALSE)
  d <- gsub("(^[[:space:]]*)rgl[[:space:]]*\\([^\\)]*\\),?", "\\1rmetal,",
            d)
  d <- gsub("(^[[:space:]]*)rgl[[:space:]]*,?", "\\1rmetal,", d)
  writeLines(d, desc)

  n <- readLines(ns, warn = FALSE)
  n <- gsub("import\\(rgl\\)", "import(rmetal)", n)
  n <- gsub("importFrom\\(rgl,", "importFrom(rmetal,", n)
  writeLines(n, ns)

  patch_roots <- file.path(path, c("R", "tests", "vignettes", "man"))
  patch_roots <- patch_roots[dir.exists(patch_roots)]
  patch_files <- unlist(lapply(patch_roots, function(root) {
    list.files(root, pattern = "\\.(R|r|Rmd|rmd|Rd)$", recursive = TRUE,
               full.names = TRUE)
  }), use.names = FALSE)

  for (file in patch_files) {
    x <- readLines(file, warn = FALSE)
    y <- gsub("library\\([[:space:]]*rgl[[:space:]]*\\)",
              "library(rmetal)", x)
    y <- gsub("require\\([[:space:]]*rgl[[:space:]]*\\)",
              "require(rmetal)", y)
    y <- gsub("rgl::", "rmetal::", y, fixed = TRUE)
    y <- gsub("\\\\link\\[rgl:", "\\\\link[rmetal:", y)
    y <- gsub("\\\\link\\[rgl\\]", "\\\\link[rmetal]", y)
    if (!identical(x, y)) {
      file.copy(file, paste0(file, ".bak-", stamp), overwrite = FALSE)
      writeLines(y, file)
    }
  }
  invisible(normalizePath(path, mustWork = TRUE))
}
