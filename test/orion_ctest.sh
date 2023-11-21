#!/bin/bash
#SBATCH -o out.ctest
#SBATCH --account=nems
set -eux

 module use modulefiles && module load landda_orion.intel.lua

ctest

wait

echo "ctest is done"
