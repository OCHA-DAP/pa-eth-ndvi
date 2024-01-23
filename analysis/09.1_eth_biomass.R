library(tidyverse)
library(sf)
library(gghdx)
gghdx()

eth_codab <- st_read(
    file.path(
        Sys.getenv("AA_DATA_DIR"), 
        "public", "raw", "eth", "cod_ab", 
        "eth_adm_csa_bofedb_2021_shp", 
        "eth_admbnda_adm1_csa_bofedb_2021.shp"))

gaul_shp <- st_read(
    file.path(
        Sys.getenv("AA_DATA_DIR"), 
        "public", "raw", "eth", "gaul", 
        "gaul1_asap_v04", 
        "gaul1_asap.shp"))

eth_shp <- gaul_shp %>%
    filter(name0 == "Ethiopia")

biomass_file <- read_delim(
    file.path(
        Sys.getenv("AA_DATA_DIR"), 
        "public", "raw", "glb", "biomasse", "warnings_ts.csv"), delim=";")

eth_biom <- biomass_file %>%
    filter(asap0_name == "Ethiopia")

eth_merged_df <- merge(eth_shp, eth_biom, by = "asap1_id") %>% 
    mutate(w_crop_char = paste(w_crop, "-", w_crop_na), 
           w_crop_na_char = str_split(w_crop_na, " with", simplify = T)[,1])

eth_legend_df <- eth_merged_df %>%
    st_drop_geometry() %>%
    distinct(w_crop, w_crop_na, w_crop_char) %>%
    arrange(w_crop)

col_vals_fn <- colorRampPalette(c("lightgreen", "pink", "pink",
                                  "#fe8181", "#fe5757", "#fe2e2e", 
                                  "#fe2e2e", "#cb2424", "darkred", "lightgreen", 
                                  "#FFC40C", "#FFC40C", "#DE900F", "#CD7710", 
                                  "#AC4313", "darkgreen", "grey", "grey"))
crop_col_vals <- setNames(col_vals_fn(nrow(eth_legend_df)), eth_legend_df$w_crop_char)

# FOR 2023
eth_merged_df_2023 <- eth_merged_df %>%
    filter(date == "2023-09-21")

ggplot() +
    geom_sf(data = eth_merged_df_2023, aes(fill = w_crop_char)) +
    geom_sf(data = eth_codab, fill = "transparent", linewidth=1) +
    geom_sf_text(data = eth_codab, aes(label = ADM1_EN), size = 4, color = "black") +
    ggtitle(label = paste0("Vegetation Performance for Croplands - Biomass"), 
            subtitle = "Last dekad of September 2023") +
    scale_fill_manual(values = crop_col_vals, na.value = "white") +
    labs(fill = "ASAP Warnings", x = "", y = "") + 
    theme(legend.key.width = unit(1, "cm"), legend.position = "right")

# FOR 2022
eth_merged_df_2022 <- eth_merged_df %>%
    filter(date == "2022-09-21")

ggplot() +
    geom_sf(data = eth_merged_df_2022, aes(fill = w_crop_char)) +
    geom_sf(data = eth_codab, fill = "transparent", linewidth=1) +
    geom_sf_text(data = eth_codab, aes(label = ADM1_EN), size = 4, color = "black") +
    ggtitle(label = paste0("Vegetation Performance for Croplands - Biomass"), 
            subtitle = "Last dekad of September 2022") +
    scale_fill_manual(values = crop_col_vals, na.value = "white") +
    labs(fill = "ASAP Warnings", x = "", y = "") + 
    theme(legend.key.width = unit(1, "cm"), legend.position = "right")

# 2023 from June to Sept
eth_merged_df_JJAS2023 <- eth_merged_df %>%
    filter(date >= "2023-06-01" & date <= "2023-09-21") %>%
    arrange(date)

ggplot() +
    geom_sf(data = eth_merged_df_JJAS2023, aes(fill = w_crop_char)) +
    #geom_sf(data = eth_codab, fill = "transparent", linewidth=1) +
    #geom_sf_text(data = eth_codab, aes(label = ADM1_EN), size = 4, color = "black") +
    ggtitle(label = paste0("Vegetation Performance for Croplands - Biomass"), 
            subtitle = "JJAS 2023") +
    scale_fill_manual(values = crop_col_vals, na.value = "white") +
    labs(fill = "ASAP Warnings", x = "", y = "") + 
    theme(legend.key.width = unit(1, "cm"), legend.position = "right") + 
    facet_wrap(.~`date`, ncol = 3)

# 2023 from June to Sept
eth_merged_df_JJAS2022 <- eth_merged_df %>%
    filter(date >= "2022-06-01" & date <= "2022-09-21") %>%
    arrange(date)

ggplot() +
    geom_sf(data = eth_merged_df_JJAS2022, aes(fill = w_crop_char)) +
    #geom_sf(data = eth_codab, fill = "transparent", linewidth=1) +
    #geom_sf_text(data = eth_codab, aes(label = ADM1_EN), size = 4, color = "black") +
    ggtitle(label = paste0("Vegetation Performance for Croplands - Biomass"), 
            subtitle = "JJAS 2022") +
    scale_fill_manual(values = crop_col_vals, na.value = "white") +
    labs(fill = "ASAP Warnings", x = "", y = "") + 
    theme(legend.key.width = unit(1, "cm"), legend.position = "right") + 
    facet_wrap(.~`date`, ncol = 3)

col_vals_fn_simp <- colorRampPalette(c("lightgrey", "lightgreen", "darkgreen",
                                  "pink", "#fe8181", "#fe5757", "#fe2e2e", "#cb2424", "darkred", "darkgrey"))
crop_col_vals_simp <- setNames(col_vals_fn_simp(10), 
                               c("Off season", "No warning", "Successful season", "Warning level 1", 
                                 "Warning level 1+", "Warning level 2", "Warning level 3", "Warning level 3+", 
                                 "Warning level 4", "No crop/rangeland"))

# 2023 from June to Sept
eth_merged_df_JJAS2023 <- eth_merged_df %>%
    filter(date >= "2023-06-01" & date <= "2023-09-21") %>%
    arrange(date)

ggplot() +
    geom_sf(data = eth_merged_df_JJAS2023, aes(fill = w_crop_na_char)) +
    #geom_sf(data = eth_codab, fill = "transparent", linewidth=1) +
    #geom_sf_text(data = eth_codab, aes(label = ADM1_EN), size = 4, color = "black") +
    ggtitle(label = paste0("Vegetation Performance for Croplands - Biomass"), 
            subtitle = "JJAS 2023") +
    scale_fill_manual(values = crop_col_vals_simp, na.value = "white") +
    labs(fill = "ASAP Warnings", x = "", y = "") + 
    theme(legend.key.width = unit(1, "cm"), legend.position = "right") + 
    facet_wrap(.~`date`, ncol = 3)

# 2023 from June to Sept
eth_merged_df_JJAS2022 <- eth_merged_df %>%
    filter(date >= "2022-06-01" & date <= "2022-09-21") %>%
    arrange(date)

ggplot() +
    geom_sf(data = eth_merged_df_JJAS2022, aes(fill = w_crop_na_char)) +
    #geom_sf(data = eth_codab, fill = "transparent", linewidth=1) +
    #geom_sf_text(data = eth_codab, aes(label = ADM1_EN), size = 4, color = "black") +
    ggtitle(label = paste0("Vegetation Performance for Croplands - Biomass"), 
            subtitle = "JJAS 2022") +
    scale_fill_manual(values = crop_col_vals_simp, na.value = "white") +
    labs(fill = "ASAP Warnings", x = "", y = "") + 
    theme(legend.key.width = unit(1, "cm"), legend.position = "right") + 
    facet_wrap(.~`date`, ncol = 3)
