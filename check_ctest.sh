#!/bin/bash
#SBATCH -o out.check
#SBATCH --account=nems
set -eux

echo "ctest check is done"
