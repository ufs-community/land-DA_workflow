#!/bin/bash

set -xue

TEST_DIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
BUILD_DIR=${TEST_DIR}/../build
PARM_DIR=${TEST_DIR}/../../parm

# Detect platform
source ${PARM_DIR}/detect_platform.sh
export MACHINE_ID=${PLATFORM}

# Copy scripts to build
cd ${BUILD_DIR}
cp -p "${TEST_DIR}/${PLATFORM}_ctest.sh" ${BUILD_DIR}/.

if [ "${PLATFORM}" = "hera" ] || [ "${PLATFORM}" = "orion" ] || [ "${PLATFORM}" = "hercules" ]; then
  JOB_ID=$(sbatch --job-name=ctest --account=epic --qos=batch --ntasks-per-node=13 --nodes=1 --time=00:30:00 ./${PLATFORM}_ctest.sh | awk '{print $4}')
else
  echo "FATAL ERROR: ctest is not available on this platform (machine)."
  exit 1
fi
