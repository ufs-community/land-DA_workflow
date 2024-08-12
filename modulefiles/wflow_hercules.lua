help([[
This module loads python environement for running the land-DA workflow on
the MSU machine Hercules
]])

whatis([===[Loads libraries needed for running the land-DA workflow on Hercules ]===])

load("contrib")
load("rocoto")

unload("python")
load("conda")

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate land_da
]===])
end
