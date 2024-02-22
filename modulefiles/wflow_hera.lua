help([[
This module loads python environement for running the land-DA workflow on
the NOAA RDHPC machine Hera
]])

whatis([===[Loads libraries needed for running the land-DA workflow on Hera ]===])

load("rocoto")

load("conda")

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate land_da
]===])
end
