help([[
This module loads python environement for running the land-DA workflow on
the MSU machine Hercules
]])

whatis([===[Loads libraries needed for running the land-DA workflow on Hercules ]===])

load("contrib")
load("rocoto")

prepend_path("MODULEPATH","/work/noaa/epic/UFS-conda-v2/modulefiles")
load("python-ufs-land-da-wflow")
