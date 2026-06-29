bg3d <- function(..., tag = NULL) {
  .rmetal_add_object("background", list(), .rmetal_material(...), tag = tag,
                     present = .rmetal_viewer_alive() ||
                       .rmetal_viewer_starting())
}

rgl.bg <- bg3d

light3d <- function(..., tag = NULL) {
  .rmetal_add_object("light", list(), .rmetal_material(...), tag = tag,
                     present = .rmetal_viewer_alive() ||
                       .rmetal_viewer_starting())
}

rgl.light <- light3d

axes3d <- function(..., tag = NULL) {
  .rmetal_add_object("axes", list(), .rmetal_material(...), tag = tag,
                     present = .rmetal_viewer_alive() ||
                       .rmetal_viewer_starting() ||
                       .rmetal_scene_has_primary_objects())
}

axis3d <- axes3d
box3d <- function(..., tag = NULL) {
  .rmetal_add_object("box", list(), .rmetal_material(...), tag = tag,
                     present = .rmetal_viewer_alive() ||
                       .rmetal_viewer_starting() ||
                       .rmetal_scene_has_primary_objects())
}

bbox3d <- box3d
rgl.bbox <- box3d
grid3d <- axes3d
title3d <- function(main = NULL, sub = NULL, xlab = NULL, ylab = NULL,
                    zlab = NULL, ..., tag = NULL) {
  .rmetal_add_object("title", list(main = main, sub = sub, xlab = xlab,
                                   ylab = ylab, zlab = zlab),
                     .rmetal_material(...), tag = tag)
}

mtext3d <- function(text, ...) text3d(c(0, 0, 0), texts = text, ...)
decorate3d <- function(...) invisible(list(...))
legend3d <- function(...) invisible(NULL)
abclines3d <- function(...) lines3d(matrix(0, nrow = 2L, ncol = 3L), ...)
arc3d <- function(x, ...) lines3d(x, ...)
arrow3d <- function(p0, p1, ...) segments3d(rbind(p0, p1), ...)
dot3d <- function(x, ...) points3d(x, ...)
particles3d <- points3d
pch3d <- points3d
sprites3d <- points3d
rgl.sprites <- sprites3d
surface3d <- function(x, y = NULL, z = NULL, ...) points3d(cbind(c(x), c(y), c(z)), ...)
rgl.surface <- surface3d
terrain3d <- surface3d
persp3d <- surface3d
filledContour3d <- surface3d
contourLines3d <- function(...) invisible(list())
polygon3d <- function(x, y = NULL, z = NULL, ...) lines3d(x, y, z, ...)
extrude3d <- function(x, ...) x
drape3d <- function(x, ...) x
clipMesh3d <- function(x, ...) x
clipObj3d <- function(x, ...) x
clipplanes3d <- function(...) invisible(NULL)
rgl.clipplanes <- clipplanes3d
clipplaneControl <- function(...) invisible(NULL)
shadow3d <- function(x, ...) x
facing3d <- function(x, ...) rep(TRUE, length(ids3d()$id))
observer3d <- function(...) c(0, 0, 1)
