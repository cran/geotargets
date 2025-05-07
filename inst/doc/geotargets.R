## -----------------------------------------------------------------------------
# With the root.dir option below,
# this vignette runs the R code in a temporary directory
# so new files are written to temporary storage
# and not the user's file space.
knitr::opts_knit$set(root.dir = fs::dir_create(tempfile()))
knitr::opts_chunk$set(
  collapse = TRUE,
  eval = TRUE,
  comment = "#>"
)

## -----------------------------------------------------------------------------
library(targets)
library(geotargets)

## -----------------------------------------------------------------------------
targets::tar_script({
  library(targets)
  library(geotargets)
  tar_option_set(packages = "terra")
  geotargets_option_set(gdal_raster_driver = "COG")
  list(
    tar_target(
      tif_file,
      system.file("ex/elev.tif", package = "terra"),
      format = "file"
    ),
    tar_terra_rast(
      r,
      {
        rast <- rast(tif_file)
        units(rast) <- "m"
        rast
      }
    ),
    tar_terra_rast(
      r_agg,
      aggregate(r, 2)
    )
  )
})

## -----------------------------------------------------------------------------
tar_make()
tar_read(r)
tar_read(r_agg)

## -----------------------------------------------------------------------------
targets::tar_script({
  # contents of _targets.R:
  library(targets)
  library(geotargets)
  tar_option_set(packages = "terra")
  geotargets_option_set(gdal_raster_driver = "COG")
  list(
    tar_target(
      tif_file,
      system.file("ex/elev.tif", package = "terra"),
      format = "file"
    ),
    tar_terra_rast(
      r,
      {
        rast <- rast(tif_file)
        units(rast) <- "m"
        rast
      },
      preserve_metadata = "zip"
    )
  )
})

## -----------------------------------------------------------------------------
tar_make()
terra::units(tar_read(r))

## -----------------------------------------------------------------------------
targets::tar_script({
  # contents of _targets.R:
  library(targets)
  library(geotargets)
  geotargets_option_set(gdal_vector_driver = "GeoJSON")
  list(
    tar_target(
      vect_file,
      system.file("ex", "lux.shp", package = "terra"),
      format = "file"
    ),
    tar_terra_vect(
      v,
      terra::vect(vect_file)
    ),
    tar_terra_vect(
      v_proj,
      terra::project(v, "EPSG:2196")
    )
  )
})

## -----------------------------------------------------------------------------
tar_make()
tar_read(v)
tar_read(v_proj)

## -----------------------------------------------------------------------------
targets::tar_script({
  # contents of _targets.R:
  library(targets)
  library(geotargets)
  elev_scale <- function(raster, z = 1, projection = "EPSG:4326") {
    terra::project(
      raster * z,
      projection
    )
  }
  tar_option_set(packages = "terra")
  geotargets_option_set(gdal_raster_driver = "GTiff")
  list(
    tar_target(
      elev_file,
      system.file("ex", "elev.tif", package = "terra"),
      format = "file"
    ),
    tar_terra_rast(
      r,
      rast(elev_file)
    ),
    tar_terra_sprc(
      raster_elevs,
      # two rasters, one unaltered, one scaled by factor of 2 and
      # reprojected to interrupted good homolosine
      terra::sprc(list(
        elev_scale(r, 1),
        elev_scale(r, 2, "+proj=igh")
      ))
    )
  )
})

## -----------------------------------------------------------------------------
tar_make()
tar_read(raster_elevs)

## -----------------------------------------------------------------------------
targets::tar_script({
  # contents of _targets.R:
  library(targets)
  library(geotargets)
  tar_option_set(packages = "terra")
  list(
    tar_target(
      logo_file,
      system.file("ex/logo.tif", package = "terra"),
      format = "file"
    ),
    tar_terra_sds(
      raster_dataset,
      {
        x <- sds(rast(logo_file), rast(logo_file) / 2)
        names(x) <- c("first", "second")
        x
      }
    )
  )
})

## -----------------------------------------------------------------------------
tar_make()
tar_read(raster_dataset)

