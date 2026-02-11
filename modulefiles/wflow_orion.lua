help([[
This module loads python environement for running the land-DA workflow on
the MSU machine Orion
]])

whatis([===[Loads libraries needed for running the land-DA workflow on Orion ]===])

load("contrib")
load("ruby/3.2.3")
load("rocoto/1.3.7")

prepend_path("MODULEPATH","/work/noaa/epic/UFS-conda-v2/modulefiles")
load("python-ufs-land-da-wflow")

