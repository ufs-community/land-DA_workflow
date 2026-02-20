#!/bin/bash
#SBATCH -o out.ctest

set -eux

module purge

module use ../../modulefiles
module load ufsland_hercules.intel
module load intel-oneapi-mkl/2024.2.1

module use /work/noaa/epic/UFS-conda-v2/modulefiles
module load python-ufs-land-da-wflow

export MPIRUN="srun"
export JEDI_PATH="/work/noaa/epic/UFS_Land-DA_v3.0/jedi_bundle_hercules"

ctest

wait

echo "ctest is done"
