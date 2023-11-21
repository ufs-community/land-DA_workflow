#!/bin/bash
#SBATCH -o out.ctest
#SBATCH --account=nems
set -eux

module use ../modulefiles && module landda_orion.intel.lua

ctest

wait

echo "ctest is done"
