help([[
This module loads python environment for running the land-DA workflow for
the singularity container.
]])

whatis([===[Loads libraries needed for running the land-DA workflow on unsupported platforms ]===])

load("rocoto")

load("conda")

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate land_da
]===])
end
