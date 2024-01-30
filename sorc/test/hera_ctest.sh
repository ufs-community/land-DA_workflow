#!/bin/bash
#SBATCH -o out.ctest
#SBATCH --account=nems
set -eux

module use ../modulefiles && module load build_hera_intel

ctest

wait

echo "ctest is done"
