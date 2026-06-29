test_that("decoration-only scenes do not block mesh_mark_pois-style drawing", {
  open3d()
  on.exit(close3d(), add = TRUE)

  view3d(theta = 0, phi = 0)
  axes3d(labels = TRUE)

  expect_equal(cur3d(), 0L)

  mesh <- tmesh3d(
    vertices = t(matrix(c(0, 0, 0,
                          1, 0, 0,
                          0, 1, 0), ncol = 3, byrow = TRUE)),
    indices = matrix(c(1, 2, 3), nrow = 3),
    homogeneous = FALSE
  )
  shade3d(mesh, color = "green")

  expect_gt(cur3d(), 0L)
  expect_equal(vapply(scene3d()$objects, `[[`, character(1), "type"),
               c("axes", "triangles"))
})

test_that("drop_poi-style removal keeps the mesh and removes only the POI", {
  testthat::skip_if_not(requireNamespace("Lithics3D", quietly = TRUE),
                        "Lithics3D is not installed")

  open3d()
  on.exit(close3d(), add = TRUE)

  mesh <- tmesh3d(
    vertices = t(matrix(c(0, 0, 0,
                          1, 0, 0,
                          0, 1, 0), ncol = 3, byrow = TRUE)),
    indices = matrix(c(1, 2, 3), nrow = 3),
    homogeneous = FALSE
  )
  shade3d(mesh, color = "green")
  points3d(matrix(c(0.2, 0.2, 0), nrow = 1), tag = 1,
           color = "red", size = 12)

  pois <- data.frame(x = 0.2, y = 0.2, z = 0, Tag = 1)
  drop_poi <- getExportedValue("Lithics3D", "drop_poi")
  pois <- drop_poi(pois)

  expect_equal(nrow(pois), 0L)
  expect_equal(tagged3d(tags = 1), integer())
  expect_equal(vapply(scene3d()$objects, `[[`, character(1), "type"),
               "triangles")
})

test_that("orient_by_vectors example scene contains axes, mesh, and landmarks", {
  testthat::skip_if_not(requireNamespace("Lithics3D", quietly = TRUE),
                        "Lithics3D is not installed")
  testthat::skip_if_not(requireNamespace("Morpho", quietly = TRUE),
                        "Morpho is not installed")

  data_env <- new.env(parent = emptyenv())
  utils::data("demoFlake2", package = "Lithics3D", envir = data_env)
  demoFlake2 <- data_env$demoFlake2

  orient_by_vectors <- getExportedValue("Lithics3D", "orient_by_vectors")
  len <- demoFlake2$lms[c(3, nrow(demoFlake2$lms)), ]
  pw <- demoFlake2$lms[c(1, nrow(demoFlake2$lms) - 1), ]
  res <- orient_by_vectors(len, pw, t(demoFlake2$mesh$vb)[, 1:3],
                           rbind(len, pw))

  view3d(theta = 0, phi = 0)
  axes3d(labels = TRUE)
  res_mesh <- list(vb = t(cbind(res$coords, 1)), it = demoFlake2$mesh$it)
  class(res_mesh) <- "mesh3d"
  shade3d(res_mesh, col = "green", alpha = 0.4)
  points3d(res$e_coords[c(1, 1), ], col = "red", size = 15)
  points3d(res$e_coords[c(2, 2), ], col = "red", size = 10)
  points3d(res$e_coords[c(3, 3), ], col = "purple", size = 15)
  points3d(res$e_coords[c(4, 4), ], col = "orange", size = 10)
  on.exit(close3d(), add = TRUE)

  scene <- scene3d()
  expect_equal(scene$par$theta, 0)
  expect_equal(scene$par$phi, 0)
  expect_equal(vapply(scene$objects, `[[`, character(1), "type"),
               c("axes", "triangles", "points", "points", "points", "points"))
  expect_match(as.character(rmetal_scene_json(scene, pretty = FALSE)),
               '"type":"axes","geometry":\\{\\}')
})

test_that("orient_by_vectors example loads in the live viewer", {
  testthat::skip_if_not(requireNamespace("Lithics3D", quietly = TRUE),
                        "Lithics3D is not installed")
  testthat::skip_if_not(requireNamespace("Morpho", quietly = TRUE),
                        "Morpho is not installed")

  data_env <- new.env(parent = emptyenv())
  utils::data("demoFlake2", package = "Lithics3D", envir = data_env)
  demoFlake2 <- data_env$demoFlake2

  orient_by_vectors <- getExportedValue("Lithics3D", "orient_by_vectors")
  len <- demoFlake2$lms[c(3, nrow(demoFlake2$lms)), ]
  pw <- demoFlake2$lms[c(1, nrow(demoFlake2$lms) - 1), ]
  res <- orient_by_vectors(len, pw, t(demoFlake2$mesh$vb)[, 1:3],
                           rbind(len, pw))
  res_mesh <- list(vb = t(cbind(res$coords, 1)), it = demoFlake2$mesh$it)
  class(res_mesh) <- "mesh3d"

  expect_live_viewer_scene_loaded({
    view3d(theta = 0, phi = 0)
    axes3d(labels = TRUE)
    shade3d(res_mesh, col = "green", alpha = 0.4)
    points3d(res$e_coords[c(1, 1), ], col = "red", size = 15)
    points3d(res$e_coords[c(2, 2), ], col = "red", size = 10)
    points3d(res$e_coords[c(3, 3), ], col = "purple", size = 15)
    points3d(res$e_coords[c(4, 4), ], col = "orange", size = 10)
  }, expected_objects = 6)
})
