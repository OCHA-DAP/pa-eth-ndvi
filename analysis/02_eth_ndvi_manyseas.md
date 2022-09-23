### NDVI Ethiopia - JJAS 2021
Same stuff as `eth_ndvi.md` but with no explanation and for several seasons. 

Some things take long to compute, but intermediate products are saved and can thus be loaded. 


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
from datetime import date, timedelta
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
    ndvi_exploration_dir,
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
# gdf_stats_mask_ond[["ADM3_PCODE", "include"]].rename(
#     columns={"include": "pastoral_lz"}
# ).to_csv(ndvi_exploration_dir / "eth_adm3_pastoral.csv", index=False)
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
gdf_stats_adm3_fma2022 = aggregate_admin(
    start_date=date(day=1, month=2, year=2022),
    end_date=date(day=1, month=5, year=2022),
    gdf=gdf_adm3,
    feature_col=pcode3_col,
)
gdf_medb_count_fma_2022 = compute_dekads_below_thresh(
    gdf_stats_adm3_fma2022, pcode3_col, "median", perc_bins, perc_labels
)
g = plot_ndvi_aggr(
    gdf_medb_count_fma_2022,
    feature_col="perc_binned",
    title=f"Percentage of dekads from"
    f" {gdf_stats_adm3_fma2022.date.min().strftime('%d-%b-%Y')} to {(gdf_stats_adm3_fma2022.date.max()+timedelta(days=6)).strftime('%d-%b-%Y')}"
    f" NDVI \n was <={threshold}% of median NDVI",
);
# g.figure.savefig(get_plot_dir() / f"{iso3}_usgs_ndvi_{pcode3_col.lower()}_fmam2022.png",
#                  facecolor="white",
#                  bbox_inches="tight",dpi=200)
```

```python
gdf_stats_adm3_ma2022 = gdf_stats_adm3_fma2022[
    gdf_stats_adm3_fma2022.date.dt.month >= 3
]
gdf_medb_count_ma_2022 = compute_dekads_below_thresh(
    gdf_stats_adm3_ma2022, pcode3_col, "median", perc_bins, perc_labels
)
g = plot_ndvi_aggr(
    gdf_medb_count_ma_2022,
    feature_col="perc_binned",
    title=f"Percentage of dekads from"
    f" {gdf_stats_adm3_ma2022.date.min().strftime('%d-%b-%Y')} to {(gdf_stats_adm3_ma2022.date.max()+timedelta(days=6)).strftime('%d-%b-%Y')}"
    f" NDVI \n was <={threshold}% of median NDVI",
);
# g.figure.savefig(get_plot_dir() / f"{iso3}_usgs_ndvi_{pcode3_col.lower()}_fmam2022.png",
#                  facecolor="white",
#                  bbox_inches="tight",dpi=200)
```

```python

```
