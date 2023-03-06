This project uses a hybrid of python and R

to run python notebooks, install 

`pip install git+https://github.com/OCHA-DAP/pa-aa-toolbox.git@ndvi#egg=aa-toolbox`

In a future release, the package can instead be installed with `pip install aa-toolbox`

Install python code in `src` using the command:

```shell
pip install -e .
```

Analyses done in R utilize `Rmds` also `analysis` folder. Any custom R functions that are sourced in a script or notebook are contained in the `R` directory. All required libraries are listed at the top of each R script/notebook. If you do not have the required packaged it can be installed with 

```shell
install.packates("nameOfPackage")
```