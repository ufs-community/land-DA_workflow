#!/bin/bash
#SBATCH -o out.ctest
#SBATCH --account=epic
set -eux

source ../../versions/build.ver_orion
module use ../../modulefiles
module load build_orion_intel

ctest

wait

echo "ctest is done"
