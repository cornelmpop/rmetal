test_that("rgl shim package source is generated", {
  path <- file.path(tempdir(), "rgl-rmetal-shim")
  unlink(path, recursive = TRUE)
  out <- create_rgl_compat_package(path)
  expect_true(file.exists(file.path(out, "DESCRIPTION")))
  expect_true(file.exists(file.path(out, "NAMESPACE")))
  expect_true(any(readLines(file.path(out, "DESCRIPTION")) == "Package: rgl"))
})
