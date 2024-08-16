#!/usr/bin/env bash
#
# A unified init script for the Land-DA_workflow application. This script is expected to
# fetch and dependent source for the Land-DA_workflow application for all supported platforms.
#
# Usage:
#  UFS_PLATFORM=<platform> UFS_COMPILER=<compiler> [ BRANCH_NAME=<branch> ] .cicd/scripts/land_init.sh
#  .cicd/scripts/land_init.sh <platform> <compiler> [ <branch> ]
#
pwd
set +x
#echo "UFS_PLATFORM=${UFS_PLATFORM}"
#echo "UFS_COMPILER=${UFS_COMPILER}"
[[ -n $1 ]] && export UFS_PLATFORM=${1} && export machine=${1,,} || export machine=${UFS_PLATFORM,,}
[[ -n $2 ]] && export UFS_COMPILER=${2} && export compiler=${2} || export compiler=${UFS_COMPILER}
[[ -n ${WORKSPACE} ]] && export workspace=${WORKSPACE} || export workspace=$(pwd)
echo "machine=${machine}"
echo "compiler=${compiler}"
echo "workspace=${workspace}"

set -e -u -x

echo "UFS_PLATFORM=${UFS_PLATFORM}"
echo "UFS_COMPILER=${UFS_COMPILER}"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

# Get repository root from Jenkins WORKSPACE variable if set, otherwise, set
# relative to script directory.
declare workspace
if [[ -d "${WORKSPACE:=$(pwd)}/${UFS_PLATFORM}" ]]; then
    workspace="${WORKSPACE:=$(pwd)}/${UFS_PLATFORM}"
else
    workspace="$(cd -- "${script_dir}/../.." && pwd)"
fi

# Normalize Parallel Works cluster platform value.
declare platform
if [[ "${UFS_PLATFORM}" =~ ^(az|g|p)clusternoaa ]]; then
    platform='noaacloud'
else
    platform="${UFS_PLATFORM}"
fi

# Initialize
cd ${workspace}
pwd
rm -f ${workspace}/${UFS_PLATFORM,,}-*.txt ${workspace}/${UFS_PLATFORM,,}-*.json
rm -f ${workspace}/${platform}-*.txt ${workspace}/${platform}-*.json
set +e

rm -rf sorc/build

[[ -n ${BRANCH_NAME:=} ]] && git checkout ${BRANCH_NAME} || true
status=${PIPESTATUS[0]}

git branch
git log -1 --oneline

/usr/bin/time -p \
	-o ${workspace}/${UFS_PLATFORM}-${UFS_COMPILER}-time-land_init.json \
	-f '{\n  "cpu": "%P"\n, "memMax": "%M"\n, "mem": {"text": "%X", "data": "%D", "swaps": "%W", "context": "%c", "waits": "%w"}\n, "pagefaults": {"major": "%F", "minor": "%R"}\n, "filesystem": {"inputs": "%I", "outputs": "%O"}\n, "time": {"real": "%e", "user": "%U", "sys": "%S"}\n}' \
	find . -name .git -type d

git status -u

init_exit=$status
echo "STAGE_NAME=${STAGE_NAME:=manual}"
env | grep = | sort > ${workspace}/${UFS_PLATFORM}-${UFS_COMPILER}-env.txt
set -e
cd -
pwd

exit $init_exit

