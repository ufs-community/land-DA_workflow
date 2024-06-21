help([[
This module loads python environement for running the land-DA workflow on
the MSU machine Orion
]])

whatis([===[Loads libraries needed for running the land-DA workflow on Orion ]===])

load("contrib")
load("ruby/3.2.3")
load("rocoto/1.3.7")

unload("python")
load("conda")

if mode() == "load" then
   LmodMsgRaw([===[Please do the following to activate conda:
       > conda activate land_da
]===])
end
