from aatoolbox import create_custom_country_config
from aatoolbox import UsgsNdviPctMedian
from pathlib import Path
iso3 = "eth"


#TODO: replace with country_config = create_country_config(iso3) once PR
#that corrects the yaml is merged in toolbox
#TODO: hmm this is ugly but somehow config.yaml is not working as filepath
#Do you know why? 
filepath = "../src/config.yaml"
country_config = create_custom_country_config(filepath=filepath)

pcode2_col="ADM2_PCODE"
pcode3_col="ADM3_PCODE"

ndvi_colors=["#724c04","#d86f27","#f0a00f","#f7c90a","#fffc8b","#e0e0e0","#86cb69","#3ca358","#39a458","#197d71","#146888","#092c7d"]
ndvi_bins=[0,60,70,80,90,95,105,110,120,130,140,250]
ndvi_labels=["<60","60-70","70-80", "80-90","90-95","95-105","105-110","110-120","120-130","130-140",">140"]

perc_bins = [0, 20, 40, 60, 80, 100]
perc_labels = ["0-20", "20-40", "40-60", "60-80", "80-100"]
# select subset of the original ndvi colors
perc_colors = ["#197d71", "#3ca358", "#f7c90a", "#d86f27", "#724c04"]
threshold = 80


ndvi_pctmedian = UsgsNdviPctMedian(
    country_config=country_config,
)
ndvi_exploration_dir=Path(*Path(ndvi_pctmedian._processed_base_dir).parts[:-3])/"exploration"/Path(*Path(ndvi_pctmedian._processed_base_dir).parts[-2:])