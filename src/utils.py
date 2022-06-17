import geopandas as gpd
import xarray as xr
import pandas as pd
from typing import List
import logging
from pathlib import Path
from aatoolbox import UsgsNdviPctMedian
from aatoolbox.utils._dates import expand_dekads
import matplotlib.pyplot as plt
import math
from matplotlib.colors import ListedColormap
from dateutil.relativedelta import relativedelta
import numpy as np

from src.datasource_extensions import LivelihoodZones, Plots
from src import constants

logger = logging.getLogger(__name__)


def retrieve_raster_data(start_date, end_date, gdf, save_file=False):
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
    if comb_filename.exists():
        da = xr.load_dataset(comb_filename)
    else:
        for date in expand_dekads(ndvi_pctmedian._start_date, ndvi_pctmedian._end_date):
            da_dekad = ndvi_pctmedian.load_raster(date)
            da_dekad_clip = da_dekad.rio.clip(
                gdf.geometry, drop=True, from_disk=True
            )
            da_dekad_list.append(da_dekad_clip.drop("spatial_ref"))
        da = xr.concat(da_dekad_list, "date")
        if save_file:
            #TODO: fix saving of this without deleting "date"
            da.drop("date").to_netcdf(comb_filename)
    return da

# TODO: ofc we want to use toolbox for this!
# but that seems to be 10x slower atm so have
# to look into the cause of that and then switch
# even with 10x faster, this takes super long to compute due to huge file sizes
# and many adm3s!
def aggregate_admin(start_date, end_date, gdf, feature_col):
    # assuming all dates in between are present in the file
    aggregated_filepath = (
        constants.ndvi_exploration_dir
        / f"{constants.iso3}_usgs_ndvi_{feature_col.lower()}_"
        f"{start_date.strftime('%d%m%Y')}_{end_date.strftime('%d%m%Y')}.csv"
    )
    stats_list = ["min", "median", "mean", "max"]
    if aggregated_filepath.exists():
        df_stats = pd.read_csv(
            aggregated_filepath, parse_dates=["date"], index_col=None
        )
        # with the old methodology the stat columns also included the feature_col name
        # so remove those without having to recompute
        df_stats = df_stats.rename(
            columns={f"{s}_{feature_col}": s for s in stats_list}
        )  # .drop("Unnamed: 0",axis=1)
    else:
        da = retrieve_raster_data(start_date, end_date, gdf)
        df_stats = da.rio.write_crs("EPSG:4326").aat.compute_raster_stats(
            gdf=gdf,
            feature_col=feature_col,
            stats_list=stats_list,
            all_touched=False,
        )
        
        df_stats["mean_binned"] = pd.cut(df_stats[f"mean"], constants.ndvi_bins)
        df_stats["median_binned"] = pd.cut(df_stats[f"median"], constants.ndvi_bins)
        df_stats["mean_binned_str"] = pd.cut(
            df_stats[f"mean"], constants.ndvi_bins, labels=constants.ndvi_labels
        )
        df_stats["median_binned_str"] = pd.cut(
            df_stats[f"median"], constants.ndvi_bins, labels=constants.ndvi_labels
        )
        df_stats.to_csv(aggregated_filepath)

    gdf_stats = gdf[[feature_col, "geometry"]].merge(df_stats, on=feature_col)

    return gdf_stats



def compute_dekads_below_thresh(
    gdf, pcode_col, value_col, perc_bins, perc_labels, threshold=80
):
    # count the number of dekads with median below threshold
    df_medb_count = (
        gdf.loc[gdf[value_col] <= threshold, [pcode_col, value_col, "date"]]
        .groupby(pcode_col, as_index=False)
        .count()
    )
    # compute percent
    df_medb_count["percent"] = (
        df_medb_count[value_col] / len(gdf.date.unique()) * 100
    )
    # create gdf again
    gdf_uniq = gdf[[pcode_col, "geometry"]].drop_duplicates()
    gdf_medb_count = gdf_uniq.merge(df_medb_count, on=pcode_col, how="outer")
    # nan value means none of the dekads were below threshold so fill them with 0
    gdf_medb_count = gdf_medb_count.fillna(0)
    # bin the values
    gdf_medb_count["perc_binned"] = pd.cut(
        gdf_medb_count["percent"],
        perc_bins,
        include_lowest=True,
        labels=perc_labels,
    )
    return gdf_medb_count

def clip_lz(gdf, lztype, pcode_col):
    gdf_lz_fn = load_livelihood_zones()
    # clip removes the admin3s that are not fully covered by (agro)pastoral livelihood zone
    gdf_clip = gpd.clip(gdf, gdf_lz_fn[gdf_lz_fn.LZTYPE.isin(lztype)])
    # determine admin3's that are (partially) (agro)pastoral
    gdf_clip["include"] = True
    gdf_include = gdf.merge(
        gdf_clip[[pcode_col, "include"]], on=pcode_col, how="left"
    )
    gdf_include["include"] = np.where(
        gdf_include.include.isnull(), False, True
    )
    gdf_include.loc[gdf_include.include == False, "perc_binned"] = np.nan
    return gdf_include

def plot_ndvi_aggr(gdf, title, feature_col, label_missing=None):
    if label_missing is None:
        # use when no missing data
        g = gdf.plot(
            feature_col,
            legend=True,
            figsize=(10, 10),
            cmap=ListedColormap(constants.perc_colors),
        )
    else:
        g = gdf.plot(
            feature_col,
            legend=True,
            figsize=(10, 10),
            cmap=ListedColormap(constants.perc_colors),
            missing_kwds={"color": "lightgrey", "label": label_missing},
        )
    g.set_title(title)
    g.axis("off")
    return g


#TODO: remove
def compute_raster_statistics(
    gdf: gpd.GeoDataFrame,
    bound_col: str,
    raster_array: xr.DataArray,
    lon_coord: str = "x",
    lat_coord: str = "y",
    stats_list: List[str] = None,
    percentile_list: List[int] = None,
    all_touched: bool = False,
    geom_col: str = "geometry",
):
    """
    Compute statistics of the raster_array per geographical region
    defined in the gdf
    the area covered by the gdf should be a subset of that
    covered by raster_array
    :param gdf: geodataframe containing a row per area for which
    the stats are computed
    :param bound_col: name of the column containing the region names
    :param raster_array: DataArray containing the raster data.
    Needs to have a CRS.
    Should not be a DataSet but DataArray
    :param lon_coord: name of longitude dimension in raster_array
    :param lat_coord: name of latitude dimension in raster_array
    :param stats_list: list with function names indicating
    which stats to compute
    :param percentile_list: list with integers ranging from 0 to 100
    indicating which percentiles to compute
    :param all_touched: if False, only cells with their centre within the
    region will be included when computing the stat.
    If True all cells touching the region will be included.
    :param geom_col: name of the column in boundary_path
    containing the polygon geometry
    :return: dataframe containing the computed statistics
    """
    df_list = []

    if stats_list is None:
        stats_list = ["mean", "std", "min", "max", "sum", "count"]

    for bound_id in gdf[bound_col].unique():
        gdf_adm = gdf[gdf[bound_col] == bound_id]

        da_clip = raster_array.rio.set_spatial_dims(
            x_dim=lon_coord, y_dim=lat_coord
        )

        # clip returns error if no overlapping raster cells for geometry
        # so catching this and skipping rest of iteration so no stats computed
        # TODO: investigate to specifically except this case
        try:
            da_clip = da_clip.rio.clip(
                gdf_adm[geom_col], all_touched=all_touched
            )
        except Exception:
            logger.warning(
                "No overlapping raster cells for %s so skipping.", bound_id
            )
            continue

        grid_stat_all = []
        for stat in stats_list:
            # count automatically ignores NaNs
            # therefore skipna can also not be given as an argument
            # implemented count cause needed for computing percentages
            kwargs = {}
            if stat != "count":
                kwargs["skipna"] = True
            # makes sum return NaN instead of 0 if array
            # only contains NaNs
            if stat == "sum":
                kwargs["min_count"] = 1
            grid_stat = getattr(da_clip, stat)(
                dim=[lon_coord, lat_coord], **kwargs
            ).rename(f"{stat}_{bound_col}")
            grid_stat_all.append(grid_stat)

        if percentile_list is not None:
            grid_quant = [
                da_clip.quantile(quant / 100, dim=[lon_coord, lat_coord])
                .drop("quantile")
                .rename(f"{quant}quant_{bound_col}")
                for quant in percentile_list
            ]
            grid_stat_all.extend(grid_quant)

        # if dims is 0, it throws an error when merging
        # and then converting to a df
        # this occurs when the input da is 2D
        if not grid_stat_all[0].dims:
            df_adm = pd.DataFrame(
                {da_stat.name: [da_stat.values] for da_stat in grid_stat_all}
            )
        else:
            zonal_stats_xr = xr.merge(grid_stat_all)
            df_adm = (
                zonal_stats_xr.to_dataframe()
                .drop("spatial_ref", axis=1)
                .reset_index()
            )
        df_adm[bound_col] = bound_id
        df_list.append(df_adm)

    df_zonal_stats = pd.concat(df_list).reset_index(drop=True)
    return df_zonal_stats

def load_livelihood_zones() -> gpd.GeoDataFrame:
    livelihood_zones = LivelihoodZones(country_config=constants.country_config)
    #original crs is wgs84 but is the same as epsg:4326
    #so change name to align with the other datasets
    return livelihood_zones.load().set_crs("EPSG:4326",allow_override=True)

def get_plot_dir() -> Path:
    plots = Plots(country_config=constants.country_config)
    return plots.get_plot_dir()