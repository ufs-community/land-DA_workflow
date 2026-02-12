#!/bin/bash
#SBATCH -o out.ctest

set -eux

module purge

module use ../../modulefiles
module load ufsland_hera.intel

module use /scratch3/NAGAPE/epic/ufs-conda/modulefiles
module load python-ufs-land-da-wflow

export MPIRUN="srun"
export JEDI_PATH="/scratch3/NAGAPE/epic/UFS_Land-DA_v3.0/jedi_bundle_hera"

ctest

wait

echo "ctest is done"
