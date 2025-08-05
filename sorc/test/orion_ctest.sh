#!/bin/bash
#SBATCH -o out.ctest

set -eux

module purge

source ../../versions/build.ver_orion
module use ../../modulefiles
module load build_orion_intel

module use /work/noaa/epic/UFS-conda/modulefiles
module load python-ufs-land-da-wflow

export MPIRUN="srun"
export JEDI_PATH="/work/noaa/epic/UFS_Land-DA_v2.1/jedi_bundle_orion"

ctest

wait

echo "ctest is done"
