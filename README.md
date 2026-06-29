# rmetal

`rmetal` is an experimental `rgl`-style compatibility layer for macOS systems
where OpenGL-based `rgl` rendering is deprecated, fragile, or no longer viable
for some workflows, especially on macOS Tahoe. It keeps the familiar R API
(`shade3d()`, `points3d()`, `lines3d()`, `scene3d()`, and friends), while the
live viewer is implemented in Swift and targets Apple's RealityKit/Metal
stack.

The first supported contract is the `rgl` surface used by `Lithics3D`:

- `shade3d()` for `mesh3d` objects
- `points3d()`, `lines3d()`, `segments3d()`, `text3d()`
- window lifecycle helpers such as `open3d()`, `cur3d()`, `close3d()`
- scene inspection helpers such as `scene3d()`, `ids3d()`, `tagged3d()`
- test helpers such as `expect_known_scene()`

## Disclaimer

`rmetal` is a public-service compatibility release developed for a specific
practical problem: allowing `Lithics3D`, and potentially other `rgl`-dependent R
workflows, to run on recent versions of macOS, especially Tahoe, where OpenGL/XQuartz-based
`rgl` rendering may fail or no longer be viable. This package exists because I am not aware of a maintained
drop-in alternative for the subset of `rgl` functionality needed
by `Lithics3D` on newer macOS systems. It is not intended as a polished graphics
library, a complete reimplementation of `rgl`, or an expert hand-written
Swift/Metal project.

The package concept, target use case, compatibility priorities, testing,
release decisions, and maintenance are mine. The implementation was developed
with substantial assistance from OpenAI Codex, including code generation and
iterative debugging. Because `rmetal` was developed as a pragmatic compatibility
bridge with substantial AI-assisted implementation, it should not be seen as
representative of my usual development model for research software that I design,
implement, and maintain directly.

I am making the package public because it may help users who would otherwise
be blocked from using `Lithics3D` on recent macOS systems. Users should treat it as experimental
infrastructure and verify that it supports their own workflows (see Current
scope below).

## Installation

Prerequisites:

- macOS 13 or later.
- R 4.2 or later.
- Apple's Swift compiler and SDK frameworks, usually installed with Xcode or
  the Xcode Command Line Tools. Check with `swiftc --version`; install the
  tools with `xcode-select --install` if needed.
- The RealityKit framework, which is supplied by the Apple SDK on supported
  macOS versions.

Install `rmetal` from GitHub:

```r
install.packages("remotes")
remotes::install_github("cornelmpop/rmetal")
```

The RealityKit viewer is compiled lazily the first time it is needed for a
cache location. If `shade3d()` or another drawing call reports a Swift compile
error, first check that `swiftc --version` works in a terminal and that Xcode
or the Command Line Tools are selected with `xcode-select -p`.

## Why not call the package `rgl`?

R imports namespaces by package name. A package named `rmetal` cannot directly
satisfy another package's `import(rgl)` directive. There are two migration
paths:

1. Patch the dependent package to import `rmetal` instead of `rgl`.
2. Use the shim generator:

```r
rmetal::create_rgl_compat_package("/tmp/rgl-rmetal")
install.packages("/tmp/rgl-rmetal", repos = NULL, type = "source")
```

That shim is a tiny package named `rgl` that re-exports `rmetal`, allowing
unmodified packages such as Lithics3D to resolve `import(rgl)` from a library
path where the shim appears before the legacy `rgl` package.

## Current scope

The primary validation target is the subset of `rgl` functionality used by
`Lithics3D`; other `rgl`-dependent workflows may work, but should be tested
explicitly.

This is not a pixel-for-pixel replacement for every historical `rgl`
feature. Run:

```r
rmetal::rmetal_compatibility_status()
```

to see which exported functions are implemented, partially implemented, or
compatibility stubs. Unsupported exported `rgl` names warn and return
`invisible(NULL)`. The implemented scene calls record typed geometry and can
be inspected through `scene3d()`, exported with `rmetal_scene_json()`, or
rendered in the live RealityKit viewer.
