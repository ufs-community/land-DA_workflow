help([[
This module loads python environement for running the land-DA workflow on
the MSU machine Orion
]])

whatis([===[Loads libraries needed for running the land-DA workflow on Orion ]===])

load("contrib")
load("rocoto")
load("wget")

unload("python")
load("conda")

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate land_da
]===])
end
