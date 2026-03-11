help([[
This module loads python environement for running the land-DA workflow with
Singularity container
]])

whatis([===[Loads libraries needed for running the land-DA workflow with Singularity container ]===])

load("rocoto")

prepend_path("PATH", "SINGULARITY_WORKING_DIR/land-DA_workflow/sorc/conda/envs/python-ufs-land-da-wflow/bin")
