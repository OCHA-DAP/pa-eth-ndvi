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
plot_fxn <- function(eth_shp, prec_file, subtitle, date){
    data_df <- prec_file[-1,] %>%
        filter(date == date) %>%
        merge(eth_shp, by = "ADM2_PCODE", all.y = TRUE)
    ggplot() +
        geom_sf(data = data_df, aes(geometry = geometry, fill = as.numeric(r3q))) + 
        ggtitle(label = "3-Month Rainfall Anomalies in Percentage",
                subtitle = subtitle) +
        scale_fill_gradient(low="lightblue", high="navyblue") +
        labs(fill = "3-month anomaly in %")
}
plot_fxn(eth_shp, prec_file, 
         subtitle = "July to September 2023", 
         date = "2023-09-21")

mam2023 <- prec_file[-1,] %>%
    filter(date == "2023-05-21")

mam23_shp <- merge(eth_shp, mam2023, by = "ADM2_PCODE", all.x = TRUE)

ggplot() +
    geom_sf(data = mam23_shp, aes(fill = as.numeric(r3q))) + 
    ggtitle(label = "3-Month Rainfall Anomalies in Percentage",
            subtitle = "March to May 2023") +
    scale_fill_gradient(low="lightblue", high="navyblue") +
    labs(fill = "3-month anomaly in %") +
    theme_hdx()
