test_that("scene store records Lithics3D-style scene objects", {
  open3d()
  on.exit(close3d(), add = TRUE)

  vertices <- t(matrix(c(0, 0, 0,
                         1, 0, 0,
                         0, 1, 0), ncol = 3, byrow = TRUE))
  mesh <- tmesh3d(vertices, matrix(c(1, 2, 3), nrow = 3), homogeneous = FALSE)

  mesh_id <- shade3d(mesh, color = "green", alpha = 0.5)
  line_id <- lines3d(rbind(c(0, 0, 0), c(1, 1, 1)), color = "black")
  point_id <- points3d(matrix(c(0.5, 0.5, 0), nrow = 1), tag = 7,
                       color = "purple")
  text_id <- text3d(c(0.5, 0.5, 0), texts = "1")

  expect_s3_class(mesh_id, "rglId")
  expect_s3_class(line_id, "rglId")
  expect_s3_class(point_id, "rglId")
  expect_s3_class(text_id, "rglId")

  scene <- scene3d()
  expect_s3_class(scene, "rglscene")
  types <- vapply(scene$objects, `[[`, character(1), "type")
  expect_true(all(c("triangles", "lines", "points", "text") %in% types))
  expect_identical(tagged3d(7), as.integer(point_id))
})

test_that("pop3d removes tagged points", {
  open3d()
  on.exit(close3d(), add = TRUE)

  id <- points3d(c(0, 0, 0), tag = "poi")
  expect_identical(tagged3d("poi"), as.integer(id))
  pop3d(id = tagged3d("poi"))
  expect_identical(tagged3d("poi"), integer())
})

test_that("par3d and view3d expose rgl viewing defaults", {
  open3d()
  on.exit(close3d(), add = TRUE)

  defaults <- par3d(c("FOV", "zoom", "mouseMode"))
  expect_equal(defaults$FOV, 30)
  expect_equal(defaults$zoom, 1)
  expect_equal(unname(defaults$mouseMode),
               c("none", "trackball", "zoom", "fov", "pull"))

  view3d()
  view <- par3d(c("FOV", "fov", "zoom"))
  expect_equal(view$FOV, 60)
  expect_equal(view$fov, 60)
  expect_equal(view$zoom, 1)
  expect_equal(scene3d()$par$FOV, 60)
})

test_that("rgl snapshot helper is structural rather than backend brittle", {
  open3d()
  points3d(c(0, 0, 0))
  scene <- expect_known_scene("unused.rds", close = TRUE)
  expect_s3_class(scene, "rglscene")
})
