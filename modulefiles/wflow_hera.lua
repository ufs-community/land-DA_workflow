help([[
This module loads python environement for running the land-DA workflow on
the NOAA RDHPC machine Hera
]])

whatis([===[Loads libraries needed for running the land-DA workflow on Hera ]===])

load("rocoto")

prepend_path("MODULEPATH","/scratch3/NAGAPE/epic/ufs-conda/modulefiles")
load("python-ufs-land-da-wflow")

