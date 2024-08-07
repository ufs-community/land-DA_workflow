#!/usr/bin/env bash
#
# A unified test script for the Land-DA_workflow application. This script is expected to
# test Land-DA_workflow model for any supported platforms.
#
pwd
set +x
echo "UFS_PLATFORM=${UFS_PLATFORM}"
echo "UFS_COMPILER=${UFS_COMPILER}"
echo "LAND_DA_RUN_TESTS=${LAND_DA_RUN_TESTS}"
[[ -n $1 ]] && export UFS_PLATFORM=${1} && export machine=${1,,} || export machine=${UFS_PLATFORM,,}
[[ -n $2 ]] && export UFS_COMPILER=${2} && export compiler=${2} || export compiler=${UFS_COMPILER}
[[ -n $3 ]] && export LAND_DA_RUN_TESTS=${3}
[[ -n ${WORKSPACE} ]] && export workspace=${WORKSPACE} || export workspace=$(pwd)
echo "machine=${machine}"
echo "compiler=${compiler}"
echo "workspace=${workspace}"

echo "HOME=${HOME}"
[[ ${machine} = hera ]] && NODE_PATH="/scratch2/NAGAPE/epic/role.epic"
[[ ${machine} = jet ]] && NODE_PATH="/mnt/lfs4/HFIP/hfv3gfs/role.epic"
[[ ${machine} = gaea ]] && NODE_PATH=""
[[ ${machine} = orion ]] && NODE_PATH="/work/noaa/epic/role-epic"
[[ ${machine} = hercules ]] && NODE_PATH="/work/noaa/epic/role-epic"
echo "NODE_PATH=${NODE_PATH}"

( set -x ; ls -ld ${NODE_PATH} && ls -al ${NODE_PATH}/. )

[[ ${machine} = hera ]] && ls -l /scratch2/NAGAPE/epic/UFS_Land-DA/inputs
[[ ${machine} = jet ]] && echo "where are inputs?"
[[ ${machine} = gaea ]] && echo "where are inputs?"
[[ ${machine} = orion ]] && ls -l /work/noaa/epic/UFS_Land-DA/inputs
[[ ${machine} = hercules ]] && ls -l /work/noaa/epic/UFS_Land-DA/inputs

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

if [[ ${platform} = derecho ]] ; then
	export ACCNR=nral0032
elif [[ ${platform} = jet ]] ; then
	export ACCNR=hfv3gfs
else
	export ACCNR=epic
fi
echo "ACCNR=${ACCNR}"

# Test
cd ${workspace}
pwd
set +e
ls -l sorc/build

if [[ true = ${LAND_DA_RUN_TESTS:=false} ]] ; then

	cp sorc/test/${machine}_ctest.sh sorc/build/
	cp sorc/test/check_ctest.sh sorc/build/
	cp sorc/test/run_${machine}_ctest.sh sorc/build/
                                        
	cd sorc/build/
	set +x
 	echo $(pwd)
                                            
	echo "Pipeline Running Land-DA Tests on ${UFS_PLATFORM} ${UFS_COMPILER} with Account=${ACCNR}."
	/usr/bin/time -p \
		-o ${WORKSPACE}/${UFS_PLATFORM}-${UFS_COMPILER}-time-land_test.json \
		-f '{\n  "cpu": "%P"\n, "memMax": "%M"\n, "mem": {"text": "%X", "data": "%D", "swaps": "%W", "context": "%c", "waits": "%w"}\n, "pagefaults": {"major": "%F", "minor": "%R"}\n, "filesystem": {"inputs": "%I", "outputs": "%O"}\n, "time": {"real": "%e", "user": "%U", "sys": "%S"}\n}' \
		./run_${machine}_ctest.sh | awk 'f;/^+ ctest$/{f=1}' | tee ${WORKSPACE}/${UFS_PLATFORM}/test-log.txt
	status=${PIPESTATUS[0]}
	echo "Pipeline Completed Land-DA Tests on ${UFS_PLATFORM} ${UFS_COMPILER}. status=$status"
	rc=$(( status+=$(egrep " ***Failed " ${WORKSPACE}/${UFS_PLATFORM}/test-log.txt 2>/dev/null | wc -l) ))
	echo "rc=$rc status=$status"
	set -x
	cd -
else
	echo "Pipeline skipping Tests on ${UFS_PLATFORM} (${machine})"
	rc=0
	status=0
fi

echo "Pipeline Completed Land-DA test on ${UFS_PLATFORM} ${UFS_COMPILER}. status=$status"
git status

test_exit=$?
echo "STAGE_NAME=${STAGE_NAME:=manual}"
env | grep = | sort > ${WORKSPACE:=$(pwd)}/${UFS_PLATFORM}-${UFS_COMPILER}-env.txt
set -e
cd -
pwd

exit $test_exit

