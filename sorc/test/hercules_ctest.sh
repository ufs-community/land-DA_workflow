#!/bin/bash
#SBATCH -o out.ctest
#SBATCH --account=epic
set -eux

source ../../versions/build.ver_hercules
module use ../../modulefiles
module load build_hercules_intel

ctest

wait

echo "ctest is done"
