library(tidyverse)
library(sf)
library(gghdx)
gghdx()

prec_file <- read_csv("https://data.humdata.org/dataset/423143be-315f-48d7-9e90-ae23738da564/resource/5765531c-826d-43be-850a-a0827c6594c3/download/eth-rainfall-adm2-5ytd.csv",
                      skip=0)

eth_shp <- st_read(
    file.path(
    Sys.getenv("AA_DATA_DIR"), 
    "public", "raw", "eth", "cod_ab", 
    "eth_adm_csa_bofedb_2021_shp", 
    "eth_admbnda_adm2_csa_bofedb_2021.shp"))

##Afar Region
plot_fxn <- function(eth_shp, prec_file, subtitle, mon_date, regions){
    data_df <- prec_file[-1,] %>%
        filter(date == mon_date) %>%
        merge(eth_shp, by = "ADM2_PCODE", all = TRUE) %>%
        mutate(across(r3q, ~ case_when(ADM1_EN %in% regions ~ r3q, .default = NA)))
    ggplot() +
        geom_sf(data = data_df, aes(geometry = geometry, fill = as.numeric(r3q))) + 
        ggtitle(label = "3-Month Rainfall Anomalies in Percentage",
                subtitle = subtitle) +
        scale_fill_gradient(low="lightblue", high="navyblue") +
        labs(fill = "3-month anomaly in %")
}
plot_fxn(eth_shp, prec_file, 
         subtitle = "July to September 2023", 
         mon_date = "2023-09-21",
         regions = "Afar")

plot_fxn(eth_shp, prec_file, 
         subtitle = "March to May 2023", 
         mon_date = "2023-05-21",
         regions = "Afar")

plot_fxn(eth_shp, prec_file, 
         subtitle = "June to Start of September 2023", 
         mon_date = "2023-09-01",
         regions = c("Amhara", "Tigray"))

plot_fxn(eth_shp, prec_file, 
         subtitle = "Mid February to Mid May 2023", 
         mon_date = "2023-05-11",
         regions = c("Amhara", "Tigray"))
