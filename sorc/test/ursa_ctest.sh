#!/bin/bash
#SBATCH -o out.ctest

set -eux

module purge
source ../../versions/build.ver_ursa
module use ../../modulefiles
module load build_ursa_intel

module use /scratch3/NAGAPE/epic/ufs-conda/modulefiles
module load python-ufs-land-da-wflow

export MPIRUN="srun"
export JEDI_PATH="/scratch3/NAGAPE/epic/UFS_Land-DA_v2.1/jedi_bundle_ursa"

ctest

wait

echo "ctest is done"
