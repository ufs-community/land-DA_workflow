#!/bin/bash
set -eux

JOB_ID=$(sbatch --job-name=ctest --account=nems --qos=debug --ntasks-per-node=6 --nodes=1 --time=00:30:00 ./hera_ctest.sh | awk '{print $4}')

CHECK_ID=$(sbatch --job-name=ctest --account=nems --qos=debug --ntasks-per-node=1 --nodes=1 --time=00:01:00 --dependency=afterok:$JOB_ID ./check_ctest.sh)

sleep 3m

if [ -f out.ctest ]; then
    cat out.ctest
else
    echo "ctest run fails to run."
fi
