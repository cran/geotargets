## -----------------------------------------------------------------------------
# With the root.dir option below,
# this vignette runs the R code in a temporary directory
# so new files are written to temporary storage
# and not the user's file space.
knitr::opts_knit$set(root.dir = fs::dir_create(tempfile()))
knitr::opts_chunk$set(
  collapse = TRUE,
  eval = TRUE,
  comment = "#>",
  fig.align = "center",
  fig.height = 5,
  fig.width = 5
)
Sys.setenv(TAR_ASK = "false")

## -----------------------------------------------------------------------------
library(geotargets)
library(targets)
library(terra)

## -----------------------------------------------------------------------------
# example SpatRaster
f <- system.file("ex/elev.tif", package = "terra")
r <- rast(f)
r

## -----------------------------------------------------------------------------
r_ext <- ext(r)
r_ext

## -----------------------------------------------------------------------------
rect_extent <- function(x, ...) {
  rect(x[1], x[3], x[2], x[4], ...)
}
plot_extents <- function(x, ...) {
  invisible(lapply(x, rect_extent, border = "hotpink", lwd = 2))
}

## -----------------------------------------------------------------------------
extend(r, 5) |> plot()
lines(r_ext, col = "hotpink", lty = 2)
points(r_ext, col = "hotpink", pch = 16)

## -----------------------------------------------------------------------------
r_tile_4 <- tile_n(r, 4)
r_tile_4

## -----------------------------------------------------------------------------
plot(r)
plot_extents(r_tile_4)
plot(r)
tile_n(r, 6) |> plot_extents()

## -----------------------------------------------------------------------------
r_grid_3x1 <- tile_grid(r, ncol = 3, nrow = 1)
r_grid_3x1
plot(r)
plot_extents(r_grid_3x1)

plot(r)
tile_grid(r, ncol = 2, nrow = 3) |> plot_extents()

## -----------------------------------------------------------------------------
fileBlocksize(r)

## -----------------------------------------------------------------------------
tile_blocksize(r)

## -----------------------------------------------------------------------------
r_block_size_1x1 <- tile_blocksize(r, n_blocks_row = 1, n_blocks_col = 1)
r_block_size_1x1
plot(r)
plot_extents(r_block_size_1x1)

## -----------------------------------------------------------------------------
r_block_size_2x1 <- tile_blocksize(r, n_blocks_row = 2, n_blocks_col = 1)
r_block_size_2x1
plot(r)
plot_extents(r_block_size_2x1)

## -----------------------------------------------------------------------------
try({
sources(r)
# force into memory
r2 <- r + 0
sources(r2)
# this now errors
tile_blocksize(r2)
})

## -----------------------------------------------------------------------------
targets::tar_script({
  # contents of _targets.R
  library(targets)
  library(geotargets)
  library(terra)
  geotargets_option_set(gdal_raster_driver = "COG")
  list(
    tar_target(
      raster_file,
      system.file("ex/elev.tif", package = "terra"),
      format = "file"
    ),
    tar_terra_rast(
      r,
      disagg(rast(raster_file), fact = 10)
    ),
    # add more layers
    tar_terra_rast(
      r_big,
      c(r, r + 100, r * 10, r / 2),
      memory = "transient"
    )
  )
})

## -----------------------------------------------------------------------------
tar_make()
tar_load(r_big)
tile_blocksize(r_big)

## -----------------------------------------------------------------------------
targets::tar_script({
  # contents of _targets.R
  library(targets)
  library(geotargets)
  library(terra)
  geotargets_option_set(gdal_raster_driver = "COG")
  tar_option_set(memory = "transient")
  list(
    tar_target(
      raster_file,
      system.file("ex/elev.tif", package = "terra"),
      format = "file"
    ),
    tar_terra_rast(
      r,
      disagg(rast(raster_file), fact = 10)
    ),
    tar_terra_rast(
      r_big,
      c(r, r + 100, r * 10, r / 2),
      memory = "transient"
    ),
    # split
    tar_terra_tiles(
      tiles,
      raster = r_big,
      tile_fun = tile_blocksize,
      description = "split raster into tiles"
    ),
    # apply
    tar_terra_rast(
      tiles_mean,
      app(tiles, \(x) mean(x, na.rm = TRUE)),
      pattern = map(tiles),
      description = "some computationaly intensive task performed on each tile"
    ),
    # combine
    tar_terra_rast(
      merged_mean,
      merge(sprc(tiles_mean)),
      description = "merge tiles into a single SpatRaster"
    )
  )
})

## -----------------------------------------------------------------------------
tar_make()

## -----------------------------------------------------------------------------
library(terra)
tar_load(tiles_mean)
op <- par(mfrow = c(2, 2))
for (i in seq_along(tiles_mean)) {
  plot(tiles_mean[[i]])
}
par(op)

## -----------------------------------------------------------------------------
plot(tar_read(merged_mean))

