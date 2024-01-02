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

bin_breaks <- c(0, 20, 40, 60, 80, 100, 120, 140, 160, 180, 200)
col_vals_fn <- colorRampPalette(c("lightblue", "navyblue"))
col_vals <- setNames(col_vals_fn(length(bin_breaks)-1), cut(bin_breaks, breaks = bin_breaks)[-1])

##Afar Region
plot_fxn <- function(eth_shp, prec_file, subtitle, mon_date, regions){
    data_df <- prec_file[-1,] %>%
        filter(date == mon_date) %>%
        merge(eth_shp, by = "ADM2_PCODE", all = TRUE) %>%
        mutate(across(r3q, ~ case_when(ADM1_EN %in% regions ~ r3q, .default = NA)),
               r3q_binned = cut(as.numeric(r3q), breaks = bin_breaks))
    ggplot() +
        geom_sf(data = data_df, aes(geometry = geometry, fill = r3q_binned)) + 
        ggtitle(label = "3-Month Rainfall Anomalies in Percentage",
                subtitle = subtitle) +
        scale_fill_manual(values = col_vals, na.value = "white") +
        labs(fill = "3-month anomaly in %") + 
        theme(legend.key.width = unit(0.5, "cm"))
}
plot_fxn(eth_shp, prec_file, 
         subtitle = "July to September 2023", 
         mon_date = "2023-09-21",
         regions = "Afar")

plot_fxn(eth_shp, prec_file, 
         subtitle = "July to September 2022", 
         mon_date = "2022-09-21",
         regions = "Afar")

plot_fxn(eth_shp, prec_file, 
         subtitle = "March to May 2023", 
         mon_date = "2023-05-21",
         regions = "Afar")

plot_fxn(eth_shp, prec_file, 
         subtitle = "March to May 2022", 
         mon_date = "2022-05-21",
         regions = "Afar")

plot_fxn(eth_shp, prec_file, 
         subtitle = "June to Start of September 2023", 
         mon_date = "2023-09-01",
         regions = c("Amhara", "Tigray"))

plot_fxn(eth_shp, prec_file, 
         subtitle = "June to Start of September 2022", 
         mon_date = "2022-09-01",
         regions = c("Amhara", "Tigray"))

plot_fxn(eth_shp, prec_file, 
         subtitle = "Mid February to Mid May 2023", 
         mon_date = "2023-05-11",
         regions = c("Amhara", "Tigray"))

plot_fxn(eth_shp, prec_file, 
         subtitle = "Mid February to Mid May 2022", 
         mon_date = "2022-05-11",
         regions = c("Amhara", "Tigray"))

### adding csv files
eth_shp_adm3 <- st_read(
    file.path(
        Sys.getenv("AA_DATA_DIR"), 
        "public", "raw", "eth", "cod_ab", 
        "eth_adm_csa_bofedb_2021_shp", 
        "eth_admbnda_adm3_csa_bofedb_2021.shp"))
csv_path <- file.path(
    Sys.getenv("AA_DATA_DIR"), 
    "public", "exploration", "eth", "ndvi")

afar_ssns <- c("mam", "jjas")
am_tig_ssns <- c("fmam", "jjas")

jjas2023_file <- read_csv(file.path(csv_path, "eth_ndvi_woreda_stats_jjas2023.csv"))
colnames(jjas2023_file)[-1] = paste("JJAS 2023", colnames(jjas2023_file)[-1])
jjas2022_file <- read_csv(file.path(csv_path, "eth_ndvi_woreda_stats_jjas2022.csv"))
colnames(jjas2022_file)[-1] = paste("JJAS 2022", colnames(jjas2022_file)[-1])
fmam2023_file <- read_csv(file.path(csv_path, "eth_ndvi_woreda_stats_fmam2023.csv"))
colnames(fmam2023_file)[-1] = paste("FMAM 2023", colnames(fmam2023_file)[-1])
fmam2022_file <- read_csv(file.path(csv_path, "eth_ndvi_woreda_stats_fmam2022.csv"))
colnames(fmam2022_file)[-1] = paste("FMAM 2022", colnames(fmam2022_file)[-1])
mam2023_file <- read_csv(file.path(csv_path, "eth_ndvi_woreda_stats_mam2023.csv"))
colnames(mam2023_file)[-1] = paste("MAM 2023", colnames(mam2023_file)[-1])
mam2022_file <- read_csv(file.path(csv_path, "eth_ndvi_woreda_stats_mam2022.csv"))
colnames(mam2022_file)[-1] = paste("MAM 2022", colnames(mam2022_file)[-1])

#put all data frames into list
df_list <- list(jjas2023_file[,c(1,5,6,7)], 
                jjas2022_file[,c(1,5,6,7)], 
                fmam2023_file[,c(1,5,6,7)], 
                fmam2022_file[,c(1,5,6,7)], 
                mam2023_file[,c(1,5,6,7)], 
                mam2022_file[,c(1,5,6,7)])      

#merge all data frames together
full_ndvi_df <- df_list %>% reduce(full_join, by="ADM3_PCODE")

#rainfall df
rain_dates <- c("2023-09-21", "2022-09-21", "2023-05-21", "2022-05-21",
                "2023-09-01", "2022-09-01", "2023-05-11", "2022-05-11")

full_rain_df <- prec_file %>%
    filter(date %in% rain_dates) %>%
    select(date, ADM2_PCODE, r3q) %>%
    mutate(r3q = as.numeric(r3q)) %>%
    pivot_wider(names_from = date, values_from = r3q, values_fn = {mean}) %>%
    rename_with(~ paste0("3-month Rainfall Anomaly for Period Ending ", .x, recycle0 = TRUE),
                starts_with("2"))

full_df <- eth_shp_adm3 %>%
    select(ADM3_PCODE, ADM3_EN, ADM2_PCODE, ADM2_EN) %>%
    st_drop_geometry() %>%
    merge(full_rain_df, by="ADM2_PCODE", all = T) %>%
    merge(full_ndvi_df, by = "ADM3_PCODE", all = T)

write_csv(full_df, file.path(csv_path, "full_seasonal_analysis.csv"))
