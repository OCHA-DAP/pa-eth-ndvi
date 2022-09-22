### NDVI Ethiopia - end of 2021
This notebook explores the NDVI at the end of 2021 and beginning of 2022 in Ethiopia. The reason for this exploration is a request to map the drought conditions at admin3 level. 

As measure we use the percentage of the median NDVI. We use this instead of the absolute NDVI since this allows us to measure the conditions relative to a standard. 

We explore how this measure of NDVI differs from Oct 2021 till beginning of Jan 2022. The first dekad of Jan 2022 is the most current data at the point of writing. We include these months since Oct-Dec is a rainy season for part of the country so we can see if the NDVI changed. There is many uncertainties on how we should interpret the NDVI, e.g. how we should take into account the [seasonal calendar](https://fews.net/file/113527). This is thus solely a statement of the NDVI at the given moments and not directly of drought. 

NDVI, and the percentage of median as we use it, is commonly reported by FewsNet, the most recent ones including NDVI of [21-30 Nov](https://fews.net/east-africa/seasonal-monitor/november-2021), [1-10 Dec](https://fews.net/east-africa/alert/december-29-2021), and [1-10 Jan](https://fews.net/east-africa/seasonal-monitor/december-2021).

We first inspect the raster data but thereafter aggregate to admin3. As aggregation method the median is chosen but there is the classic problem of differences in admin sizes. 

While we first inspect the data per dekad, it was requested to create a graph of cumulative NDVI over the Oct-Dec season. While we are not NDVI experts, it didn't seem sensible to take a sum or median. We therefore instead look at the percentage of dekads where the NDVI is below x% of the median. 

```python
%load_ext autoreload
%autoreload 2
%load_ext jupyter_black

from matplotlib.colors import ListedColormap
import pandas as pd
import matplotlib.pyplot as plt

from datetime import date
```

```python
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

```python
# load admin boundaries
codab = CodAB(country_config=country_config)
gdf_adm3 = codab.load(admin_level=3)
gdf_adm2 = codab.load(admin_level=2)
pcode3_col = "ADM3_PCODE"
```

```python
# define start and end of season
start_date = date(day=1, month=10, year=2021)
end_date = date(day=1, month=1, year=2022)
```

```python
# takes some time but when saving file,
# date is dropped which we need later
# should find a way to save with date in there
raster_ond = retrieve_raster_data(
    start_date=start_date,
    end_date=end_date,
    gdf=gdf_adm3,
)
# change to datetime
# would think there is nicer way to go about it
raster_ond["date"] = [
    pd.to_datetime(d.strftime("%Y-%m-%d")) for d in raster_ond.date.values
]
# 255 indicates nan values, should also be changed in retrieve_raster_data
# function
raster_ond = raster_ond.where(raster_ond != 255)
```

```python
# plot first dekads of each month
raster_ond.sel(date=raster_ond.date.dt.day == 1).plot.imshow(
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

## Aggregation


Next we aggregate the data to the admin level. In general it is not recommended to aggregate to all these admins without a clear goal. But since requested we do an attempt. 

There are different methods of aggregation:
- min
- max
- mean
- median
- perc of area

Due to high fluctuations in the data, we estimate the min and max to not represent the situation accurately. 
The percentage of area brings an extra complexity as we then have to set a threshold. We therefore choose to not do that at this point. However, an option could be to set a threshold, e.g. <=100, and look at the perc of each adm being below that threshold. 

Based on the above we suggest to use the mean or median. Due to relatively high fluctuations, I suggest to use the median.


#### Adm3 vs Adm2
It was requested to aggregate the data to adm3. We quickly inspect how they look compared to the admin2's.We can see that there are more than 1000 admin3's. However, due to the high resolution of the data (what is the exact resolution?) and the large size of the country, we still expect it to be okay to aggregate to admin3 if needed.  

```python
print(f"Number of adm3s: {len(gdf_adm3)}")
print(f"Number of adm2s: {len(gdf_adm2)}")
```

```python
fig, axs = plt.subplots(1, 2, figsize=(10, 20))
gdf_adm3.boundary.plot(ax=axs[0])
axs[0].set_title("ADMIN3 boundaries")
gdf_adm2.boundary.plot(ax=axs[1])
axs[1].set_title("ADMIN2 boundaries");
```

#### Aggregated to admin3
Below the values per admin3 are shown. We use the same bins as [those used by USGS/FewsNet](https://earlywarning.usgs.gov/fews/product/448). 
We can see the same pattern as we saw with the raw data, which is a good sign. We see that in the beginning of October most of the country saw median conditions. This moved to below median NDVI conditions in the South-East. Towards the end of December the conditions return to median in the east, but below median conditions are seen in the Middle of the country. However, these plots should only be seen as the NDVI and not perse drought conditions as this e.g. depends on the rainy seasons. 

```python
# compute stats. If file already exists, load that
gdf_stats_adm3 = aggregate_admin(
    start_date=start_date,
    end_date=end_date,
    gdf=gdf_adm3,
    feature_col=pcode3_col,
)
```

```python
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

```python
fig = plt_ndvi_dates(
    gdf_stats_adm3,
    f"median_binned_{pcode3_col}",
    caption="Data is aggregated from raster to admin3 by taking the median",
)
```

### "Cumulative" NDVI
We were asked to combine the data from Oct-Dec to one graph. This can be slightly tricky as NDVI can be seen as a cumulative indicator by itself. We chose to report the percentage of dekads that thad a NDVI that was below x% of the median. We think this is a sensible metric, but in the future we would advise to get an opinion on this from expert, e.g. at FAO or USGS
We set the threshold at 80, i.e. below 80% of the median

```python
gdf_medb_count = compute_dekads_below_thresh(
    gdf_stats_adm3, pcode3_col, "median", perc_bins, perc_labels, threshold=80
)
```

#### Create map
We create a map with quintile bins as we think this gives enough granularity. We can see that most admin3's in the north didn't see NDVI values that were a lot below median. However, in the south we see this was a common occurence. 

```python
g = plot_ndvi_aggr(
    gdf_medb_count,
    feature_col="perc_binned",
    title=f"Percentage of dekads Oct-Dec 2021 NDVI \n was <={threshold}% of median NDVI",
)
```

### Clip to (agro)pastoral
In Ethiopia the Oct-Dec is not the relevant season for each part of the country and each type of livelihood. We were asked to only focus on the (agro)pastoral areas, and thus below we clip out the admin3's that are not (partially) (agro)pastoral

A dataset of livelihood zones was shared with us. After inspection it turns out this is the same as the [2009 livelihood zone map by FewsNet](https://fews.net/data_portal_download/download?data_file_path=http://shapefiles.fews.net.s3.amazonaws.com/LHZ/ET_LHZ_2009.zip) which is publicly available. We thus use this one. Note that FewsNet also has a [2018 update](https://fews.net/data_portal_download/download?data_file_path=http://s3.amazonaws.com/shapefiles.fews.net/LHZ/ET_LHZ_2018.zip), but since the 2009 data was shared with us, we sticked to that one. 

```python
gdf_lz_fn = load_livelihood_zones()
```

```python
# quick plot of livelihood zones
g = gdf_lz_fn.plot("LZTYPE", legend=True)
g.axes.axis("off");
```

#### Mask out none (agro)pastoral

```python
gdf_stats_mask = clip_lz(
    gdf=gdf_medb_count,
    lztype=["Pastoral", "Agropastoral"],
    pcode_col=pcode3_col,
)
```

```python
g = plot_ndvi_aggr(
    gdf_stats_mask,
    feature_col="perc_binned",
    label_missing="non-pastoralist area",
    title=f"Percentage of dekads Oct-Dec 2021 NDVI \n was <={threshold}% of median NDVI",
)
```
