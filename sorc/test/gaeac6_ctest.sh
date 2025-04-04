#!/bin/bash
#SBATCH -o out.ctest

set -eux

module purge
source ../../versions/build.ver_gaeac6
module use ../../modulefiles
module load build_gaeac6_intel

export MPIRUN="srun"
export JEDI_PATH="/gpfs/f6/bil-fire8/world-shared/UFS_Land-DA_v2.1/jedi_bundle_sync"

ctest

wait

echo "ctest is done"
