### NDVI Ethiopia - JJAS 2021
Same stuff as `eth_ndvi.md` but with no explanation and for several seasons. 

Some things take long to compute, but intermediate products are saved and can thus be loaded. 


#### Aggregated to admin3
Below the values per admin3 are shown. We use the same bins as [those used by USGS/FewsNet](https://earlywarning.usgs.gov/fews/product/448). 
We can see the same pattern as we saw with the raw data, which is a good sign. We see that in the beginning of October most of the country saw median conditions. This moved to below median NDVI conditions in the South-East. Towards the end of December the conditions return to median in the east, but below median conditions are seen in the Middle of the country. However, these plots should only be seen as the NDVI and not perse drought conditions as this e.g. depends on the rainy seasons. 


### "Cumulative" NDVI
We were asked to combine the data from Oct-Dec to one graph. This can be slightly tricky as NDVI can be seen as a cumulative indicator by itself. We chose to report the percentage of dekads that thad a NDVI that was below x% of the median. We think this is a sensible metric, but in the future we would advise to get an opinion on this from expert, e.g. at FAO or USGS

```python
%load_ext autoreload
%autoreload 2
%load_ext jupyter_black
```

```python
import numpy as np
import pandas as pd
from matplotlib.colors import ListedColormap
import math
import matplotlib.pyplot as plt
from dateutil.relativedelta import relativedelta
from datetime import date
```

```python
from aatoolbox import CodAB
from src.constants import (
    ndvi_colors,
    country_config,
    pcode3_col,
    perc_bins,
    perc_labels,
    threshold,
)

from src.utils import (
    get_plot_dir,
    aggregate_admin,
    compute_dekads_below_thresh,
    clip_lz,
    plot_ndvi_aggr,
)
```

```python
codab = CodAB(country_config=country_config)
gdf_adm3 = codab.load(admin_level=3)
```

```python
gdf_stats_adm3_2021 = aggregate_admin(
    start_date=date(day=1, month=6, year=2021),
    end_date=date(day=1, month=1, year=2022),
    gdf=gdf_adm3,
    feature_col=pcode3_col,
)
```

```python
gdf_stats_adm3_ond = gdf_stats_adm3_2021[
    (gdf_stats_adm3_2021.date >= "2021-10-01")
    & (gdf_stats_adm3_2021.date <= "2021-12-31")
]
gdf_medb_count_ond = compute_dekads_below_thresh(
    gdf_stats_adm3_ond, pcode3_col, "median", perc_bins, perc_labels
)
gdf_stats_mask_ond = clip_lz(
    gdf=gdf_medb_count_ond,
    lztype=["Pastoral", "Agropastoral"],
    pcode_col=pcode3_col,
)
g = plot_ndvi_aggr(
    gdf_stats_mask_ond,
    feature_col="perc_binned",
    label_missing="non-pastoralist area",
    title=f"Percentage of dekads Oct-Dec 2021 NDVI \n was <={threshold}% of median NDVI",
)
# g.figure.savefig(get_plot_dir() / f"{iso3}_usgs_ndvi_{pcode3_col.lower()}_ond2021.png",
#                  facecolor="white",
#                  bbox_inches="tight",dpi=200)
```

```python
gdf_stats_adm3_jjas = gdf_stats_adm3_2021[
    (gdf_stats_adm3_2021.date >= "2021-06-01")
    & (gdf_stats_adm3_2021.date <= "2021-09-30")
]
gdf_medb_count_jjas = compute_dekads_below_thresh(
    gdf_stats_adm3_jjas, pcode3_col, "median", perc_bins, perc_labels
)
gdf_stats_mask_jjas = clip_lz(
    gdf_medb_count_jjas,
    lztype=["Cropping", "Agropastoral"],
    pcode_col=pcode3_col,
)
g = plot_ndvi_aggr(
    gdf_stats_mask_jjas,
    feature_col="perc_binned",
    label_missing="non-cropping area",
    title=f"Percentage of dekads June-Sep 2021 NDVI \n was <={threshold}% of median NDVI",
)
# g.figure.savefig(
#     get_plot_dir() / f"{iso3}_usgs_ndvi_{pcode3_col.lower()}_jjas2021.png",
#     facecolor="white",
#     bbox_inches="tight",
#     dpi=200,
# )
```

```python
gdf_stats_mask_jjas_sel = gdf_stats_mask_jjas.drop(
    ["geometry", "date"], axis=1
).rename(
    columns={
        "median_ADM3_PCODE": "num_dekad_below80",
        "percent": "perc_dekad_below80",
        "perc_binned": "perc_dekad_below80_bin",
        "include": "cropping_lz",
    }
)
# gdf_stats_mask_jjas_sel.to_csv(ndvi_exploration_dir / "eth_usgs_ndvi_adm3_jjas2021_perc80.csv",index=False)
```

```python
gdf_stats_adm3_fmam_2021 = aggregate_admin(
    start_date=date(day=1, month=2, year=2021),
    end_date=date(day=21, month=5, year=2021),
    gdf=gdf_adm3,
    feature_col=pcode3_col,
)
gdf_medb_count_fmam_2021 = compute_dekads_below_thresh(
    gdf_stats_adm3_fmam_2021, pcode3_col, "median", perc_bins, perc_labels
)
g = plot_ndvi_aggr(
    gdf_medb_count_fmam_2021,
    feature_col="perc_binned",
    title=f"Percentage of dekads Feb-May 2021 NDVI \n was <={threshold}% of median NDVI",
);
# g.figure.savefig(get_plot_dir() / f"{iso3}_usgs_ndvi_{pcode3_col.lower()}_fmam2021.png",
#                  facecolor="white",
#                  bbox_inches="tight",dpi=200)
```

```python
gdf_stats_adm3_fmam_2021_sel = gdf_stats_adm3_fmam_2021.drop(
    ["geometry", "date"], axis=1
).rename(
    columns={
        "median_ADM3_PCODE": "num_dekad_below80",
        "percent": "perc_dekad_below80",
        "perc_binned": "perc_dekad_below80_bin",
        "include": "cropping_lz",
    }
)
# gdf_stats_adm3_fmam_2021_sel.to_csv(ndvi_exploration_dir / "eth_usgs_ndvi_adm3_fmam2021_perc80.csv",index=False)
```

```python

```

```python
# def plt_ndvi_dates(gdf_stats, data_col, colp_num=3, caption=None):
#     num_plots = len(gdf_stats.date.unique())
#     if num_plots == 1:
#         colp_num = 1
#     rows = math.ceil(num_plots / colp_num)
#     position = range(1, num_plots + 1)
#     fig = plt.figure(figsize=(10 * colp_num, 10 * rows))
#     for i, d in enumerate(gdf_stats.date.unique()):
#         ax = fig.add_subplot(rows, colp_num, i + 1)
#         gdf_stats[gdf_stats.date == d].plot(
#             ax=ax,
#             column=data_col,
#             legend=True,
#             categorical=True,
#             cmap=ListedColormap(constants.ndvi_colors),
#         )
#         ax.set_title(
#             f"{pd.to_datetime(str(d)).strftime('%d-%m-%Y')} till "
#             f"{(pd.to_datetime(str(d))+relativedelta(days=9)).strftime('%d-%m-%Y')}"
#         )
#         ax.axis("off")
#     if caption:
#         plt.figtext(0.7, 0.2, caption)
#     plt.suptitle("Percent of median NDVI", size=24, y=0.9)
#     return fig
```

```python
# #this is not giving the desired result yet
# plt_ndvi_dates(gdf_stats_adm3_ond,pcode3_col)
```
