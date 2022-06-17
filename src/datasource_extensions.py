from pathlib import Path

import geopandas as gpd
import pandas as pd
from aatoolbox.config.countryconfig import CountryConfig
from aatoolbox.datasources.datasource import DataSource


# TODO: Fix this -- either make a separate ABC or make it work
#  better from the toolbox
class _DataSourceExtension(DataSource):
    def __init__(self, country_config: CountryConfig):
        super().__init__(
            country_config,
            datasource_base_dir=self._DATASOURCE_BASENAME,
            is_public=self._IS_PUBLIC,
        )
        if hasattr(self, "_RAW_FILENAME"):
            self._raw_filepath = self._raw_base_dir / self._RAW_FILENAME
        if hasattr(self, "_PROCESSED_FILENAME"):
            self.processed_filepath = (
                self._processed_base_dir / self._PROCESSED_FILENAME
            )
        #TODO: need a better method to define the exploration_dir
        self._exploration_dir=Path(*Path(self._processed_base_dir).parts[:-3])/"exploration"/Path(*Path(self._processed_base_dir).parts[-2:])
        if hasattr(self, "_EXPLORATION_FILENAME"):
            self.exploration_filepath = (self._exploration_dir / 
            self._EXPLORATION_FILENAME)
    
    def download(self):
        pass
    def process(self):
        pass

#TODO: need a better method to define filepaths to datasources
#that are not part of toolbox
class LivelihoodZones(_DataSourceExtension):
    _DATASOURCE_BASENAME = "ET_LHZ_2009"
    _EXPLORATION_FILENAME = "ET_LHZ_2009.shp"
    _IS_PUBLIC = True

    def load(self) -> gpd.GeoDataFrame:
        return gpd.read_file(self.exploration_filepath)

class Plots(_DataSourceExtension):
    _DATASOURCE_BASENAME = "plots"
    _IS_PUBLIC = True

    def get_plot_dir(self) -> Path:
        return self._exploration_dir

    def load(self):
        pass