help([[
This module loads python environement for running the land-DA workflow on
the NOAA RDHPC machine Gaea-C6
]])

whatis([===[Loads libraries needed for running the land-DA workflow on Gaea-C6 ]===])

prepend_path("MODULEPATH","/ncrc/proj/epic/rocoto/modulefiles/")
load("rocoto")

prepend_path("MODULEPATH","/gpfs/f6/bil-fire8/world-shared/ufs-conda/modulefiles")
load("python-ufs-land-da-wflow")

pushenv("MKLROOT", "/opt/intel/oneapi/mkl/2023.2.0/")

