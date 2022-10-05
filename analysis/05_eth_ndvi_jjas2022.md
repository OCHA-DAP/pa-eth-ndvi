# NDVI Analysis for Ethiopia JJAS 2022

### Replicating similar analysis done for 2021
Similar analysis was done for the 2021 seasons which are described in the notebooks `01_eth_ndvi_ond2021.md` and `02_eth_ndvi_manyseas.md`
using the percent of median data found [here](https://edcintl.cr.usgs.gov/downloads/sciweb1/shared/fews/web/africa/east/dekadal/emodis/ndvi_c6/percentofmedian/downloads/dekadal/).




```py3
%load_ext autoreload
%autoreload 2
%load_ext jupyter_black

from matplotlib.colors import ListedColormap
import pandas as pd
import matplotlib.pyplot as plt
# import geopandas as gpd
import os

from datetime import date
```

##### Importing required functions


```py3
from aatoolbox import CodAB
from src.constants import (
    ndvi_colors,
    ndvi_bins,
    ndvi_labels,
    country_config,
    pcode3_col,
    perc_bins,
    perc_labels,
    threshold,
    ndvi_exploration_dir,
)

from src.utils import (
    retrieve_raster_data,
    get_plot_dir,
    aggregate_admin,
    compute_dekads_below_thresh,
    clip_lz,
    plot_ndvi_aggr,
    plt_ndvi_dates,
    load_livelihood_zones,
)
```

##### Loading Admin Boundaries


```py3
# load admin boundaries
codab = CodAB(country_config=country_config)
gdf_adm3 = codab.load(admin_level=3)
pcode3_col = "ADM3_PCODE"
```

Adding these lines as on Windows, there may be a problem that was resolved earlier in the year on reading of zipped shapefiles which may not have been applied to the branch of the toolbox being used.


```py3
#filename3 = (
#    "zip://"
#    + os.getenv("AA_DATA_DIR")
#    + "/public/raw/eth/cod_ab/eth_cod_ab.shp.zip/eth_admbnda_adm3_csa_bofedb_2021.shp"
#)
#gdf_adm3 = gpd.read_file(filename3)
```

##### Setting start and end date of analysis
Note: The start date is the first date of the first dekad to be analysed. The end date is the first date of the last dekad to be used in the analysis.


```py3
# define start and end of season
start_date = date(day=1, month=6, year=2022)
end_date = date(day=11, month=9, year=2022)
```

##### Getting raster data
The following section will take some time the first time it is run since it has to download the NDVI raster. Ensure the internet connection is stable during the initial download to reduce chances of IncompleteRead Errors. Once the download is done, the code reads the data and will not take so much time. If having problems running this, download the raster files, extract the .tif file and rename it using the naming scheme eaYYYY_PPpct, where YYYY is the 4-digit year and PP is the 2-digit pentad of the year (01-72). Add the file to the folder `\public\raw\glb\usgs_ndvi`.


```py3
### If this section works, then the aggregate admin function should be okay.
# takes some time but when saving file,
# date is dropped which we need later
# should find a way to save with date in there
raster_jjas = retrieve_raster_data(
    start_date=start_date,
    end_date=end_date,
    gdf=gdf_adm3,
)
# change to datetime
# would think there is nicer way to go about it
raster_jjas["date"] = [
    pd.to_datetime(d.strftime("%Y-%m-%d")) for d in raster_jjas.date.values
]
# 255 indicates nan values, should also be changed in retrieve_raster_data
# function
raster_jjas = raster_jjas.where(raster_jjas != 255)
```

Plotting the first dekads of June, July, August and September.


```py3
# plot first dekads of each month
raster_jjas.sel(date=raster_jjas.date.dt.day == 1).plot.imshow(
    col="date",
    levels=ndvi_bins,
    cmap=ListedColormap(ndvi_colors),
    figsize=(40, 10),
    cbar_kwargs={
        "orientation": "horizontal",
        "shrink": 0.8,
        "aspect": 40,
        "pad": 0.1,
        "ticks": ndvi_bins,
    },
);
```

##### Computing stats and aggregating to admin3
If running for the first time, set save_file argument to True to save output to a file. Remove argument or set to False otherwise. Takes ~30 minutes.


```py3
# compute stats. If file already exists, load that
gdf_stats_adm3 = aggregate_admin(
    start_date=start_date,
    end_date=end_date,
    gdf=gdf_adm3,
    feature_col=pcode3_col,
    save_file=False,
)
```


```py3
gdf_stats_adm3[gdf_stats_adm3["ADM3_PCODE"] == "ET160037"]
```


```py3
# I really have no clue why but basically have to recreate the
# column to be able to plot
# maybe smth with variable being of type category, but even just changing
# the type didn't help
gdf_stats_adm3[f"median_binned_{pcode3_col}"] = pd.cut(
    gdf_stats_adm3[f"median"],
    ndvi_bins,
    labels=ndvi_labels,
)
```


```py3
fig = plt_ndvi_dates(
    gdf_stats_adm3,
    f"median_binned_{pcode3_col}",
    caption="Data is aggregated from raster to admin3 by taking the median",
)
```


```py3
gdf_medb_count = compute_dekads_below_thresh(
    gdf_stats_adm3, pcode3_col, "median", perc_bins, perc_labels, threshold=80
)
g = plot_ndvi_aggr(
    gdf_medb_count,
    feature_col="perc_binned",
    title=f"Percentage of dekads Jun-Sep 2022 NDVI \n was <={threshold}% of median NDVI",
)
```


```py3
gdf_lz_fn = load_livelihood_zones()
# quick plot of livelihood zones
g = gdf_lz_fn.plot("LZTYPE", legend=True)
g.axes.axis("off");
```


```py3
gdf_stats_mask = clip_lz(
    gdf=gdf_medb_count,
    lztype=["Pastoral", "Agropastoral"],
    pcode_col=pcode3_col,
)
g = plot_ndvi_aggr(
    gdf_stats_mask,
    feature_col="perc_binned",
    label_missing="non-pastoralist area",
    title=f"Percentage of dekads Jun-Sep 2022 NDVI \n was <={threshold}% of median NDVI",
)
```

From the analysis of the JJAS 2022 season, most of the agropastoral regions experienced vegetation conditions close to the median except for a few admin3s. The season progression showed some signs of worsening vegetation conditions towards September.
