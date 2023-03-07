

#' ee_date_range_anomaly
#'
#' @param x 
#' @param time_range \code{character}
#' @param baseline_years \code{numeric} vector containing years to be considered in long-term historical baseline 
#' @param type \code{character} type of anomaly to calculate (z_score, pct_mean, pct_median)-- not implemented yet -just z-score
#' @param fit_gamma \code{logical} whether to apply gamma probability function to fit distribution (default =F)
#'  not implemented yet. 
#' @description a faster and more general function for calculating standard/z scores
#' @return ee.Image with pixel-level anomaly values. Once `type` argument is implemented it will have different bands depending on anomalies chosen
#'
#' @examples \dontrun{
#' library(rgee)
#'  ee_Initialize()
#chirps_link <- "UCSB-CHG/CHIRPS/DAILY"
#chirps_ic<- rgee::ee$ImageCollection(chirps_link)

#' }
ee_date_range_anomaly <- function(x,
                                  time_range,
                                  baseline_years=NULL,
                                  type=c("z_score","pct_mean"),
                                  fit_gamma=F
){
    
    
    num_days <- time_length((ymd(time_range[2]) +1)-ymd(time_range[1]),unit = "days")
    end_month <-  month(time_range[2])
    end_day <-  day(time_range[2])
    
    #xoi = x_of_interest
    xoi <- x$filterDate(time_range[1],
                        ee$Date(time_range[2])$advance(1,"day")
    )
    
    xoi_summarised <- xoi$
        sum()$
        set("system:time_start", time_range[1])$
        set("system:time_end", ee$Date(time_range[2])$advance(1,"day"))$
        set("used_images",xoi$size())
    
    
    if(is.null(baseline_years)){
        start_date_base <- ee$Date(ee$List(x$get('date_range'))$get(0))
        end_date_base <- ee$Date(time_range[2])$advance(1,"day")
        x_base <- x$filterDate(start_date_base, end_date_base)
    }
    if(!is.null(baseline_years)){
        start_date_base <- ee$Date(paste0(baseline_years[1],"-01-01"))
        end_date_base <- ee$Date(paste0(baseline_years[length(baseline_years)],"-12-31"))$advance(1,"day")
        x_base <- x$filterDate(start_date_base, end_date_base)
    }
    year_list_ee <- x_base$
        aggregate_array("system:time_start")$
        map(rgee::ee_utils_pyfunc(
            function(time_start){
                yr_string <- ee$Date(time_start)$format("YYYY")
                ee$Number$parse(yr_string)
                
            }))$distinct()
    
    x_base_filt <- rgee::ee$ImageCollection$fromImages(
        year_list_ee$map(rgee::ee_utils_pyfunc(
            function (y) {
                end_date_temp <- ee$Date$fromYMD( y,end_month, end_day)$advance(1,"day")
                start_date_temp <- end_date_temp$advance(-num_days,"day")
                x_base$
                    filterDate(start_date_temp, end_date_temp)$
                    sum()$
                    set('system:time_start',start_date_temp)$
                    set('system:time_end',end_date_temp)
                
            }
            
        ))
    )
    
    x_base_mean <- x_base_filt$
        mean()
    
    x_base_sd <- x_base_filt$reduce(ee$Reducer$stdDev())
    
    xoi_x_base_diff <- xoi_summarised$subtract(x_base_mean)
    
    xoi_x_base_diff$divide(x_base_sd)
    
}

