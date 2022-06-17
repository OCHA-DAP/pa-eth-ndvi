### NDVI Ethiopia - JJAS 2021
Same stuff as `eth_ndvi.md` but with no explanation and also including the JJAS season. 

Some things take long to compute, but most intermediate products are saved and can thus be loaded. 
Will clean up later. 

```python
# %load_ext autoreload
# %autoreload 2

# import geopandas as gpd
# from pathlib import Path
# import sys
# import os
# import math

# import xarray as xr
# import numpy as np
# from matplotlib.colors import ListedColormap
# import pandas as pd
# import matplotlib.pyplot as plt
# from dateutil.relativedelta import relativedelta

# path_mod = f"{Path.cwd().parents[3]}/"
# sys.path.append(path_mod)
# from src.indicators.drought.config import Config

# from src.indicators.drought.ndvi import (download_ndvi,load_raw_dekad_ndvi,
#                                          _dekad_to_date, _date_to_dekad)
# from src.utils_general.raster_manipulation import compute_raster_statistics
```

```python
%load_ext autoreload
%autoreload 2
%load_ext jupyter_black
```

```python
from src import constants
```

```python
from aatoolbox import CodAB
```

```python
import aatoolbox.utils.raster
```

```python
# TODO: add packages to requirements
```

```python
import xarray as xr
```

```python
import geopandas as gpd
```

```python
from matplotlib.colors import ListedColormap
```

```python
from pathlib import Path
```

```python
from netCDF4 import Dataset
```

```python
codab = CodAB(country_config=constants.country_config)
gdf_adm2 = codab.load(admin_level=2)
gdf_adm3 = codab.load(admin_level=3)
```

```python
# iso3="eth"
# config=Config()
# parameters = config.parameters(iso3)
# country_data_raw_dir = Path(config.DATA_DIR) / config.PUBLIC_DIR / config.RAW_DIR / iso3
# country_data_exploration_dir = Path(config.DATA_DIR) / config.PUBLIC_DIR / "exploration" / iso3
# ndvi_exploration_dir = country_data_exploration_dir / "ndvi"
# adm2_bound_path=country_data_raw_dir / config.SHAPEFILE_DIR / parameters["path_admin2_shp"]
# adm3_bound_path=country_data_raw_dir / config.SHAPEFILE_DIR / parameters["path_admin3_shp"]
```

```python
pcode2_col = "ADM2_PCODE"
pcode3_col = "ADM3_PCODE"
```

```python
ndvi_colors = [
    "#724c04",
    "#d86f27",
    "#f0a00f",
    "#f7c90a",
    "#fffc8b",
    "#e0e0e0",
    "#86cb69",
    "#3ca358",
    "#39a458",
    "#197d71",
    "#146888",
    "#092c7d",
]
ndvi_bins = [0, 60, 70, 80, 90, 95, 105, 110, 120, 130, 140]
ndvi_labels = [
    "<60",
    "60-70",
    "70-80",
    "90-95",
    "95-105",
    "105-110",
    "110-120",
    "120-130",
    "130-140",
    ">140",
]
```

### NDVI rasters


The NDVI raster files can be found [here](https://edcintl.cr.usgs.gov/downloads/sciweb1/shared/fews/web/africa/east/dekadal/emodis/ndvi_c6/percentofmedian/downloads/dekadal/) and can be automatically downloaded using the code


From the plots we can conclude two main points:
1) During all three dekads there were significant areas that saw below median NDVI (brown-yellow)
2) The pattern is different for the dekads in 2021 than the latest dekad. Where for the first two the worst NDVI conditions are seen in the south and East, while in the latest dekad the worst conditions are in the South but also more up north in the middle of the country. 

```python
dekad_list_fmam_2022 = [[2022, d] for d in range(4, 14)]
```

```python
start_date = "2022-02-01"
end_date = "2022-05-12"
```

```python
from aatoolbox import UsgsNdviPctMedian

ndvi_pctmedian = UsgsNdviPctMedian(
    country_config=constants.country_config,
    start_date="2022-02-01",
    end_date="2022-05-12",
)
```

```python
ndvi_exploration_dir = (
    Path(*Path(ndvi_pctmedian._processed_base_dir).parts[:-3])
    / "exploration"
    / Path(*Path(ndvi_pctmedian._processed_base_dir).parts[-2:])
)
```

```python
# ndvi_pctmedian.download()
```

```python
# ndvi_pctmedian.process(gdf=gdf_adm3,feature_col="ADM3_EN",stats_list=["min","median","mean","max"],)
```

```python
# # takes about 3 minutes
# da_dekad_list=[]
# for year_dekad in dekad_list_fmam_2022:
#     da_dekad = ndvi_pctmedian.load_raster(year_dekad)
#     da_dekad_clip=da_dekad.rio.clip(gdf_adm3.geometry, drop=True, from_disk=True)
#     da_dekad_list.append(da_dekad_clip.drop("spatial_ref"))
# da_orig=xr.concat(da_dekad_list,"date")
# da_orig.to_dataset(name="ndvi_pctmedian").to_netcdf(ndvi_exploration_dir/"eth_raster_feb2022_may2022.nc")
```

```python
ndvi_exploration_dir / "eth_raster_feb2022_may2022.nc"
```

```python
# da=xr.load_dataarray(ndvi_exploration_dir/"eth_raster_feb2022_may2022 copy.nc",engine="netcdf4")
```

```python
from aatoolbox.utils._dates import date_to_dekad, get_dekadal_date
```

```python
from src.utils import retrieve_raster_data
```

```python
from aatoolbox.utils._dates import expand_dekads
```

```python
ndvi_pctmedian = UsgsNdviPctMedian(
    country_config=constants.country_config,
    start_date=start_date,
    end_date=end_date,
)
ndvi_pctmedian.download()
da_dekad_list = []
comb_filename = (
    constants.ndvi_exploration_dir / f"{constants.iso3}_"
    f"usgs_ndvi_{ndvi_pctmedian._start_date}_{ndvi_pctmedian._end_date}.nc"
)
# if comb_filename.exists():
#     da = xr.load_dataset(comb_filename)
# else:
for date in expand_dekads(
    ndvi_pctmedian._start_date, ndvi_pctmedian._end_date
):
    da_dekad = ndvi_pctmedian.load_raster(date)
    da_dekad_clip = da_dekad.rio.clip(
        gdf_adm3.geometry, drop=True, from_disk=True
    )
    da_dekad_list.append(da_dekad_clip.drop("spatial_ref"))
da = xr.concat(da_dekad_list, "date")
```

```python
da.indexes["date"]
```

```python
da.drop("date")
```

```python
# da.indexes["date"].to_datetimeindex()
```

```python
da_dekad
```

```python
# dont know anymore what I was doing here
# retrieve_raster_data(start_date, end_date, gdf=gdf_adm3, save_file=True)
```

```python
g= da.sel(date="2022-05-01").plot.imshow(
#     col="date",
    levels=ndvi_bins,
    cmap=ListedColormap(ndvi_colors),
    figsize=(10,10),
    col_wrap=5,
    cbar_kwargs={
    "orientation": "horizontal",
    "shrink": 0.8,
    "aspect": 40,
    "pad": 0.1,
    'ticks': ndvi_bins,
    "label": "NDVI percent of median"
    },
);
g.axes.axis("off")
# for ax in g.axes:#.flat:
#     ax.axis("off")
# g.fig.savefig(ndvi_exploration_dir/"plots"/"eth_usgs_ndvi_fmam2022_raster_pctmedian.png", facecolor="white", bbox_inches="tight")
```

```python
g= da.plot.imshow(
    col="date",
    levels=ndvi_bins,
    cmap=ListedColormap(ndvi_colors),
    figsize=(20,10),
    col_wrap=5,
    cbar_kwargs={
    "orientation": "horizontal",
    "shrink": 0.8,
    "aspect": 40,
    "pad": 0.1,
    'ticks': ndvi_bins,
    "label": "NDVI percent of median"
    },
);
for ax in g.axes.flat:
    ax.axis("off")
# g.fig.savefig(ndvi_exploration_dir/"plots"/"eth_usgs_ndvi_fmam2022_raster_pctmedian.png", facecolor="white", bbox_inches="tight")
```

### Define functions

```python
10:32 - 10:52
```

```python
df_stats = da.rio.write_crs("EPSG:4326").aat.compute_raster_stats(
        gdf=gdf_adm3,
        feature_col=pcode3_col,
        stats_list=["min","median","mean","max"],
        all_touched=False,
    )
```

```python
def aggregate_admin(da,gdf,pcode_col,bins=None):
#     da_clip = da.rio.clip(gdf.geometry, drop=True, from_disk=True)
    df_stats = da.aat.compute_raster_stats(
        gdf=gdf,
        feature_col=pcode_col,
        stats_list=["min","median","mean","max"],
        all_touched=False,
    )
#     df_stats=compute_raster_statistics(
#         gdf=gdf,
#         bound_col=pcode_col,
#         raster_array=da_clip,
#         lon_coord="x",
#         lat_coord="y",
#         stats_list=["min","median","mean","max"],
#         all_touched=False,
#     )
    #would like better way to do this
    #dont understand why but df_stats_adm2.convert_dtypes() is not working
    df_stats[f"mean_{pcode_col}"]=df_stats[f"mean_{pcode_col}"].astype("float64")
    df_stats[f"median_{pcode_col}"]=df_stats[f"median_{pcode_col}"].astype("float64")
    if bins is not None: 
        df_stats["mean_binned"]=pd.cut(df_stats[f"mean_{pcode_col}"],bins)
        df_stats["median_binned"]=pd.cut(df_stats[f"median_{pcode_col}"],bins)
    gdf_stats=gdf[[pcode_col,"geometry"]].merge(df_stats,on=pcode_col)
    gdf_stats["median_binned_str"]=pd.cut(gdf_stats[f"median_{pcode_col}"],ndvi_bins,labels=ndvi_labels)
    return gdf_stats
```

```python
def get_stats(df_stats,gdf,pcode_col,bins=None):
    #would like better way to do this
    #dont understand why but df_stats_adm2.convert_dtypes() is not working
#     df_stats[f"mean_{pcode_col}"]=df_stats[f"mean_{pcode_col}"].astype("float64")
#     df_stats[f"median_{pcode_col}"]=df_stats[f"median_{pcode_col}"].astype("float64")
    if bins is not None: 
        df_stats["mean_binned"]=pd.cut(df_stats[f"mean"],bins)
        df_stats["median_binned"]=pd.cut(df_stats[f"median"],bins)
    gdf_stats=gdf[[pcode_col,"geometry"]].merge(df_stats,on=pcode_col)
    gdf_stats["median_binned_str"]=pd.cut(gdf_stats[f"median"],ndvi_bins,labels=ndvi_labels)
    return gdf_stats
```

```python
def plt_ndvi_dates(gdf_stats,data_col,colp_num=3,caption=None):
    num_plots = len(gdf_stats.date.unique())
    if num_plots==1:
        colp_num=1
    rows = math.ceil(num_plots / colp_num)
    position = range(1, num_plots + 1)
    fig=plt.figure(figsize=(10*colp_num,10*rows))
    for i,d in enumerate(gdf_stats.date.unique()):
        ax = fig.add_subplot(rows,colp_num,i+1)
        gdf_stats[gdf_stats.date==d].plot(ax=ax, column=data_col,
                             legend=True,#if i==num_plots-1 else False,
                            categorical=True,
                cmap=ListedColormap(ndvi_colors)
         )
        ax.set_title(f"{pd.to_datetime(str(d)).strftime('%d-%m-%Y')} till "
                     f"{(pd.to_datetime(str(d))+relativedelta(days=9)).strftime('%d-%m-%Y')}")
        ax.axis("off")
    if caption:
        plt.figtext(0.7, 0.2,caption)
    plt.suptitle("Percent of median NDVI",size=24,y=0.9)
    return fig

```

#### Aggregated to admin3
Below the values per admin3 are shown. We use the same bins as [those used by USGS/FewsNet](https://earlywarning.usgs.gov/fews/product/448). 
We can see the same pattern as we saw with the raw data, which is a good sign. We see that in the beginning of October most of the country saw median conditions. This moved to below median NDVI conditions in the South-East. Towards the end of December the conditions return to median in the east, but below median conditions are seen in the Middle of the country. However, these plots should only be seen as the NDVI and not perse drought conditions as this e.g. depends on the rainy seasons. 

```python
#The AAT compute raster stats seems to take a lot longer than our original?
```

```python
df_stats
```

```python
import pandas as pd
```

```python
gdf_stats_adm3=get_stats(df_stats,gdf_adm3,pcode3_col,bins=ndvi_bins)
```

```python
# # #this takes a couple of minutes to compute
# # #only needed first time, else can load the file below
gdf_stats_adm3=aggregate_admin(da.rio.write_crs("EPSG:4326"),gdf_adm3,pcode3_col,bins=ndvi_bins)
# #save file
# gdf_stats_adm3[["ADM3_PCODE","date","year","dekad","median_ADM3_PCODE","median_binned_str"]].rename(
#     columns={"median_binned_str":"median_binned_ADM3_PCODE"}).to_csv(
#     ndvi_exploration_dir/"eth_ndvi_adm3_022021-052021.csv")
```

```python
import pandas as pd
```

```python
df_stats_adm3 = pd.read_csv(ndvi_exploration_dir/f"eth_usgs_ndvi_adm3_01022022_01052022.csv",parse_dates=["date"])
gdf_stats_adm3=gdf_adm3[["geometry",pcode3_col]].merge(df_stats_adm3,how="right")
```

```python
# #read files
# df_stats_adm3_junjan=pd.read_csv(ndvi_exploration_dir/"eth_ndvi_adm3_062021-012022.csv",parse_dates=['date'])
# df_stats_adm3_fmam=pd.read_csv(ndvi_exploration_dir/"eth_ndvi_adm3_022021-052021.csv",parse_dates=['date'])
# df_stats_adm3=pd.concat([df_stats_adm3_fmam,df_stats_adm3_junjan])
# gdf_stats_adm3=gdf_adm3[["geometry",pcode3_col]].merge(df_stats_adm3,how="right")
```

### "Cumulative" NDVI
We were asked to combine the data from Oct-Dec to one graph. This can be slightly tricky as NDVI can be seen as a cumulative indicator by itself. We chose to report the percentage of dekads that thad a NDVI that was below x% of the median. We think this is a sensible metric, but in the future we would advise to get an opinion on this from expert, e.g. at FAO or USGS

```python
thresh=80
```

```python
def compute_dekads_below_thresh(gdf,pcode_col,value_col):
    #count the number of dekads with median below thresh
    df_medb_count=gdf.loc[gdf[value_col]<=thresh,
                          [pcode_col,value_col,"date"]].groupby(pcode_col,as_index=False).count()
    #compute percent
    df_medb_count["percent"]=df_medb_count[value_col]/len(gdf.date.unique())*100
    #create gdf again
    gdf_uniq=gdf[[pcode3_col,"geometry"]].drop_duplicates()
    gdf_medb_count=gdf_uniq.merge(df_medb_count,on=pcode_col,how="outer")
    #nan value means none of the dekads were below thresh so fill them with 0
    gdf_medb_count=gdf_medb_count.fillna(0)
    #bin the values
    gdf_medb_count["perc_binned"]=pd.cut(gdf_medb_count["percent"],perc_bins,include_lowest=True,labels=perc_labels)
    return gdf_medb_count
```

```python
def clip_lz(gdf,lztype):
    gdf_lz_fn=gpd.read_file(country_data_exploration_dir/"ET_LHZ_2009/ET_LHZ_2009.shp")
    #clip removes the admin3s that are not fully covered by (agro)pastoral livelihood zone
    gdf_clip=gpd.clip(gdf,gdf_lz_fn[gdf_lz_fn.LZTYPE.isin(lztype)])
    #determine admin3's that are (partially) (agro)pastoral
    gdf_clip["include"]=True
    gdf_include=gdf.merge(gdf_clip[[pcode3_col,"include"]],on=pcode3_col,how="left")
    gdf_include["include"]=np.where(gdf_include.include.isnull(),False,True)
    gdf_include.loc[gdf_include.include==False,"perc_binned"]=np.nan
    return gdf_include                      
```

```python
def plot_ndvi(gdf,title):
    #use when no missing data
    g=gdf.plot(
        "perc_binned",
        legend=True,
        figsize=(10,10),
        cmap=ListedColormap(perc_colors),
    )
    g.set_title(title);
    g.axis("off");
    return g
```

```python
def plot_mask(gdf,label_missing,title):
    g=gdf.plot(
        "perc_binned",
        legend=True,
        figsize=(10,10),
        cmap=ListedColormap(perc_colors),
        missing_kwds={"color": "lightgrey",
                      "label": label_missing}
    )
    g.set_title(title);
    g.axis("off");
    return g
```

```python
perc_bins=[0,20,40,60,80,100]
#select subset of the original ndvi colors
perc_colors=["#724c04","#d86f27","#f7c90a","#3ca358","#197d71"]
perc_colors.reverse()
perc_labels=["0-20","20-40","40-60","60-80","80-100"]
```

```python
# gdf_stats_adm3_ond=gdf_stats_adm3[gdf_stats_adm3.date.isin(
#     [_dekad_to_date(dek[0],dek[1]) for dek in dekad_list_ond])]
# gdf_medb_count_ond=compute_dekads_below_thresh(gdf_stats_adm3_ond,pcode3_col,"median_ADM3_PCODE")
# gdf_stats_mask_ond=clip_lz(gdf_medb_count_ond,['Pastoral','Agropastoral'])
# g=plot_mask(gdf_stats_mask_ond,
#           label_missing='non-pastoralist area',
#           title=f"Percentage of dekads Oct-Dec 2021 NDVI \n was <={thresh}% of median NDVI")
# # g.figure.savefig(country_data_exploration_dir / "plots" / "eth_ndvi_adm3_ond2021.png", 
# #                  facecolor="white", 
# #                  bbox_inches="tight",dpi=200)
```

```python
# gdf_stats_adm3_jjas=gdf_stats_adm3[gdf_stats_adm3.date.isin(
#     [_dekad_to_date(dek[0],dek[1]) for dek in dekad_list_jjas])]
# gdf_medb_count_jjas=compute_dekads_below_thresh(gdf_stats_adm3_jjas,pcode3_col,"median_ADM3_PCODE")
# #this takes long due to the large number of cropping areas
# gdf_stats_mask_jjas=clip_lz(gdf_medb_count_jjas,['Cropping','Agropastoral'])
# g=plot_mask(gdf_stats_mask_jjas,
#           label_missing='non-cropping area',
#           title=f"Percentage of dekads June-Sep 2021 NDVI \n was <={thresh}% of median NDVI")
# # g.figure.savefig(country_data_exploration_dir / "plots" / "eth_ndvi_adm3_jjas2021.png", facecolor="white", bbox_inches="tight")
```

```python
# gdf_stats_mask_jjas_sel=gdf_stats_mask_jjas.drop(['geometry','date'],axis=1).rename(
#     columns={'median_ADM3_PCODE':'num_dekad_below80',
#              'percent':'perc_dekad_below80','perc_binned':'perc_dekad_below80_bin',
#             'include':'cropping_lz'})
# # gdf_stats_mask_jjas_sel.to_csv(ndvi_exploration_dir / "eth_ndvi_adm3_jjas2021_perc80.csv",index=False)
```

```python
gdf_stats_adm3
```

```python
from aatoolbox.utils._dates import dekad_to_date
```

```python
import matplotlib.pyplot as plt
```

```python
gdf_stats_adm3[gdf_stats_adm3.date=="2022-02-01"].sort_values('median')
```

```python
g= da.plot.imshow(
    col="date",
    levels=ndvi_bins,
    cmap=ListedColormap(ndvi_colors),
    figsize=(20,10),
    col_wrap=5,
    cbar_kwargs={
    "orientation": "horizontal",
    "shrink": 0.8,
    "aspect": 40,
    "pad": 0.1,
    'ticks': ndvi_bins,
    "label": "NDVI percent of median"
    },
);
for ax in g.axes.flat:
    ax.axis("off")
# g.fig.savefig(ndvi_exploration_dir/"plots"/"eth_usgs_ndvi_fmam2022_raster_pctmedian.png", facecolor="white", bbox_inches="tight")
```

```python
import matplotlib.colors as mcolors

```

```python
fig, axes = plt.subplots(
    ncols=4, nrows=(len(gdf_stats_adm3.date.unique())//4+1), sharex=True, sharey=True, figsize=(15, 20)
)
axes_list = [item for sublist in axes for item in sublist]

# Loop through to make the plots
for date, selection in gdf_stats_adm3.groupby("date"):
    ax = axes_list.pop(0)
    selection.plot(
        column="median_binned", label=date, ax=ax, 
#         legend_kwds={'orientation': "horizontal", 'shrink': 0.8}, 
#         cbar_kwargs={'ticks':ndvi_bins},
#         norm=mcolors.BoundaryNorm(boundaries=ndvi_bins,ncolors=len(ndvi_colors)),
        legend=True, cmap=ListedColormap(ndvi_colors)
    )
    ax.set_title(date)
    ax.spines["left"].set_visible(False)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.set_axis_off()

# handles, labels = ax.get_legend_handles_labels()
# fig.legend(handles, labels, loc='upper center')
# # Now use the matplotlib .remove() method to
# # delete anything we didn't use
for ax in axes_list:
    ax.remove()
# patch_col = ax.collections[0]
# cb = fig.colorbar(patch_col, ax=axes, shrink=0.5)

plt.tight_layout()
#     plt.savefig(os.path.join(output_dir, "time_series.png"), dpi=300)
```

```python
gdf_stats_adm3_fmam.date.min().strftime("%d-%m-%Y")
```

```python
from datetime import timedelta
```

```python
(gdf_stats_adm3_fmam.date.max()+timedelta(days=6)).strftime("%d-%m-%Y")
```

```python
gdf_stats_adm3_fmam.dekad.min()
```

```python
#unclear what we should mask, so not applying any atm
gdf_stats_adm3_fmam=gdf_stats_adm3[gdf_stats_adm3.date.isin(
    [dekad_to_date([dek[0],dek[1]]) for dek in dekad_list_fmam_2022])]
gdf_medb_count_fmam=compute_dekads_below_thresh(gdf_stats_adm3_fmam,pcode3_col,"median")
#this takes long due to the large number of cropping areas
g=plot_ndvi(gdf_medb_count_fmam,title=(
    f"Percentage of dekads from"
    f" {gdf_stats_adm3_fmam.date.min().strftime('%d-%b-%Y')} to {(gdf_stats_adm3_fmam.date.max()+timedelta(days=6)).strftime('%d-%b-%Y')}"
    f" NDVI \n was <={thresh}% of median NDVI"));
# g.figure.savefig(ndvi_exploration_dir / "plots" / "eth_usgs_ndvi_pct_dekads_belmed_adm3_fmam2022.png", facecolor="white", bbox_inches="tight")
```

```python
#unclear what we should mask, so not applying any atm
gdf_stats_adm3_mam=gdf_stats_adm3[gdf_stats_adm3.date.isin(
    [dekad_to_date([dek[0],dek[1]]) for dek in dekad_list_fmam_2022[3:]])]
gdf_medb_count_mam=compute_dekads_below_thresh(gdf_stats_adm3_mam,pcode3_col,"median")
#this takes long due to the large number of cropping areas
g=plot_ndvi(gdf_medb_count_mam,title=(
    f"Percentage of dekads from"
    f" {gdf_stats_adm3_mam.date.min().strftime('%d-%b-%Y')} to {(gdf_stats_adm3_mam.date.max()+timedelta(days=6)).strftime('%d-%b-%Y')}"
    f" NDVI \n was <={thresh}% of median NDVI"));
# g.figure.savefig(ndvi_exploration_dir / "plots" / "eth_usgs_ndvi_pct_dekads_belmed_adm3_mam2022.png", facecolor="white", bbox_inches="tight")
```

```python
gdf_stats_adm3_mam.date.min()
```

```python
gdf_medb_count_mam_sel=gdf_medb_count_mam.drop(['geometry','date'],axis=1).rename(
    columns={'median':'num_dekad_below80',
             'percent':'perc_dekad_below80','perc_binned':'perc_dekad_below80_bin',
            })
gdf_medb_count_mam_sel.to_csv(
    ndvi_exploration_dir / 
    f"eth_usgs_ndvi_adm3_{gdf_stats_adm3_mam.date.min().strftime('%d%m%Y')}_{gdf_stats_adm3_mam.date.max().strftime('%d%m%Y')}_perc80.csv",index=False)
```

```python
gdf_stats_adm3[["ADM3_PCODE","date","year","dekad","median","median_binned_str"]].rename(
    columns={"median_binned_str":"median_binned"}).to_csv(
    ndvi_exploration_dir/f"eth_usgs_ndvi_adm3_{gdf_stats_adm3.date.min().strftime('%d%m%Y')}_{gdf_stats_adm3.date.max().strftime('%d%m%Y')}.csv")
```

```python

```
