#!/usr/bin/env bash
#
# A unified test script for the Land-DA_workflow application. This script is expected to
# test Land-DA_workflow model for any supported platforms.
#
# Usage:
#  UFS_PLATFORM=<platform> UFS_COMPILER=<compiler> [ LAND_DA_EXPERIMENT=<exp> ] .cicd/scripts/land_experiment.sh
#  .cicd/scripts/land_experiment.sh <platform> <compiler> [ <exp>|default ]
#
pwd
export REPO_NAME="land-DA_workflow"

[[ -n $1 ]] && export UFS_PLATFORM=${1}
[[ -n $2 ]] && export UFS_COMPILER=${2}
[[ -n $3 ]] && export LAND_DA_EXPERIMENT=${3}

[[ -n ${UFS_PLATFORM} ]] || echo "Error: UFS_PLATFORM must be set."
[[ -n ${UFS_COMPILER} ]] || export UFS_COMPILER="intel"
[[ -n ${LAND_DA_EXPERIMENT} ]] || export LAND_DA_EXPERIMENT=""

[[ -n ${WORKSPACE} ]] && export workspace=${WORKSPACE} || export workspace=$(pwd)

set +x

echo "workspace=${workspace}"
echo "HOME=${HOME}"

echo "UFS_PLATFORM=${UFS_PLATFORM}"
echo "UFS_COMPILER=${UFS_COMPILER}"
echo "LAND_DA_EXPERIMENT=${LAND_DA_EXPERIMENT}"

set -e -u -x

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

echo "ACCNR=${ACCNR}"

# Test
cd ${workspace}
pwd

set +e

git branch
git log -1 --oneline

status=0

ls -al .cicd/scripts
if [[ -x .cicd/scripts/run_experiment.sh ]] ; then
	/usr/bin/time -p \
		-o ${workspace}/${UFS_PLATFORM}-${UFS_COMPILER}-time-land_expr.json \
		-f '{\n  "cpu": "%P"\n, "memMax": "%M"\n, "mem": {"text": "%X", "data": "%D", "swaps": "%W", "context": "%c", "waits": "%w"}\n, "pagefaults": {"major": "%F", "minor": "%R"}\n, "filesystem": {"inputs": "%I", "outputs": "%O"}\n, "time": {"real": "%e", "user": "%U", "sys": "%S"}\n}' \
		.cicd/scripts/run_experiment.sh ${UFS_PLATFORM} ${UFS_COMPILER} ${LAND_DA_EXPERIMENT} | tee ${workspace}/${UFS_PLATFORM}-${UFS_COMPILER}-experiment-log.txt
	status=${PIPESTATUS[0]}

	[[ -f ${workspace}/${UFS_PLATFORM,,}-wflow_experiment-log.txt ]] || (( status+=1 ))
	rc=$(( status+=$(egrep "FAILURE|DEAD" ${workspace}/${UFS_PLATFORM,,}-wflow_experiment-log.txt 2>/dev/null | wc -l) ))
	echo "rc=$rc status=$status"
else
	echo "Error: can't run_experiment.sh ..."
	(( status+=1 ))
fi

git status -u

test_exit=$status
echo "STAGE_NAME=${STAGE_NAME:=manual}"
env | grep = | sort > ${workspace}/${UFS_PLATFORM}-${UFS_COMPILER}-env.txt
set -e
cd -
pwd

exit $test_exit

