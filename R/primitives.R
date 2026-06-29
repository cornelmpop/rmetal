identityMatrix <- function() diag(4)

translationMatrix <- function(x, y = NULL, z = NULL) {
  xyz <- as.numeric(.rmetal_xyz(x, y, z)[1L, ])
  m <- diag(4)
  m[1:3, 4] <- xyz
  m
}

scaleMatrix <- function(x, y = x, z = x) {
  diag(c(x, y, z, 1))
}

rotationMatrix <- function(angle, x, y = NULL, z = NULL, matrix = TRUE) {
  axis <- as.numeric(.rmetal_xyz(x, y, z)[1L, ])
  n <- sqrt(sum(axis^2))
  if (!is.finite(n) || n == 0) return(diag(4))
  axis <- axis / n
  ux <- axis[1]; uy <- axis[2]; uz <- axis[3]
  c <- cos(angle); s <- sin(angle)
  r <- matrix(c(
    c + ux * ux * (1 - c), ux * uy * (1 - c) - uz * s, ux * uz * (1 - c) + uy * s,
    uy * ux * (1 - c) + uz * s, c + uy * uy * (1 - c), uy * uz * (1 - c) - ux * s,
    uz * ux * (1 - c) - uy * s, uz * uy * (1 - c) + ux * s, c + uz * uz * (1 - c)
  ), nrow = 3L, byrow = TRUE)
  out <- diag(4)
  out[1:3, 1:3] <- r
  out
}

transform3d <- function(obj, matrix, ...) {
  if (inherits(obj, "mesh3d")) {
    obj$vb <- matrix %*% obj$vb
    return(obj)
  }
  coords <- .rmetal_xyz(obj)
  homo <- cbind(coords, 1)
  out <- t(matrix %*% t(homo))[, 1:3, drop = FALSE]
  colnames(out) <- c("x", "y", "z")
  out
}

translate3d <- function(obj, x, y = NULL, z = NULL, ...) {
  transform3d(obj, translationMatrix(x, y, z))
}

scale3d <- function(obj, x, y = x, z = x, ...) {
  transform3d(obj, scaleMatrix(x, y, z))
}

rotate3d <- function(obj, angle, x, y = NULL, z = NULL, ...) {
  transform3d(obj, rotationMatrix(angle, x, y, z))
}

normalize.mesh3d <- function(obj, ...) {
  vb <- t(obj$vb[1:3, , drop = FALSE])
  center <- colMeans(vb)
  span <- max(abs(sweep(vb, 2, center)))
  if (is.finite(span) && span > 0) {
    obj$vb[1:3, ] <- t(sweep(vb, 2, center) / span)
  }
  obj
}

addNormals <- function(x, ...) x
mergeVertices <- function(x, ...) x
divide.mesh3d <- function(x, ...) x
subdivision3d <- function(x, ...) x
deform.mesh3d <- function(x, ...) x

cube3d <- function(...) {
  v <- rbind(
    c(-1, -1, -1), c(1, -1, -1), c(1, 1, -1), c(-1, 1, -1),
    c(-1, -1, 1), c(1, -1, 1), c(1, 1, 1), c(-1, 1, 1)
  )
  q <- matrix(c(1, 2, 3, 4, 5, 8, 7, 6, 1, 5, 6, 2,
                2, 6, 7, 3, 3, 7, 8, 4, 4, 8, 5, 1),
              nrow = 4L)
  qmesh3d(t(v), q, homogeneous = FALSE, ...)
}

tetrahedron3d <- function(...) {
  v <- t(matrix(c(1, 1, 1, -1, -1, 1, -1, 1, -1, 1, -1, -1), ncol = 3L,
                byrow = TRUE))
  it <- matrix(c(1, 2, 3, 1, 4, 2, 3, 2, 4, 1, 3, 4), nrow = 3L)
  tmesh3d(v, it, homogeneous = FALSE, ...)
}

octahedron3d <- function(...) tetrahedron3d(...)
icosahedron3d <- function(...) tetrahedron3d(...)
dodecahedron3d <- function(...) cube3d(...)
cuboctahedron3d <- function(...) cube3d(...)

asHomogeneous <- function(x) cbind(.rmetal_xyz(x), 1)
asEuclidean <- function(x) {
  x <- as.matrix(x)
  if (ncol(x) >= 4L) x[, 1:3, drop = FALSE] / x[, 4L] else x[, 1:3, drop = FALSE]
}
asHomogeneous2 <- asHomogeneous
asEuclidean2 <- asEuclidean
asRow <- function(x) matrix(x, nrow = 1L)
GramSchmidt <- function(x, ...) qr.Q(qr(x))
