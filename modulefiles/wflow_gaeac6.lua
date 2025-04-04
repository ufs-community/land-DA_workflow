help([[
This module loads python environement for running the land-DA workflow on
the NOAA RDHPC machine Gaea-C6
]])

whatis([===[Loads libraries needed for running the land-DA workflow on Gaea-C6 ]===])

unload("python")
prepend_path("MODULEPATH","/ncrc/proj/epic/rocoto/modulefiles/")
load("rocoto")
load("conda")

pushenv("MKLROOT", "/opt/intel/oneapi/mkl/2023.2.0/")

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate land_da
]===])
end
