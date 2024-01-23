spi_zonal_stats <- function(spi_raster,
                            poly, 
                            poly_cols=c("ADM1_EN","ADM2_EN","ADM2_PCODE","ADM3_EN","ADM3_PCODE")){
    spi_raster_reclass <-  spi_raster
    spi_raster_reclass[spi_raster_reclass>-2] <- NA
    spi_raster_reclass[spi_raster_reclass<=-2] <- 1
    
    lte2_stats <- exact_extract(spi_raster_reclass,
                                # transform
                                st_transform(x = poly,crs = st_crs(spi_raster_reclass)),
                                append_cols=poly_cols,
                                # include_area=T,
                                # coverage_fraction=T,
                                c("count")
    ) 
    median_stats <-exact_extract(spi_raster,
                                 st_transform(x = poly,crs = st_crs(spi_raster)),
                                 append_cols=poly_cols,
                                 fun=c("mean","median","count")
    ) 
    poly_stats <- median_stats %>% 
        rename(total_pixels="count") %>% 
        left_join(
            lte2_stats %>% 
                rename(pixels_lte_neg2 = "count")
        ) %>% 
        mutate(
            pct_lte_neg2 = (round((pixels_lte_neg2/total_pixels)*100,1))
        )
    
    poly_stats_spatial <- poly %>% 
        left_join(
            poly_stats 
        )
    return(poly_stats_spatial)
    
}