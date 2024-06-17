#!/bin/bash
set -ex
################################################
# pass arguments
project_binary_dir=$1
project_source_dir=$2

#
echo ${project_binary_dir}
echo ${project_source_dir}

#
MACHINE_ID=${MACHINE_ID:-hera}
TEST_NAME=datm_cdeps_lnd_gswp3
PATHRT=${project_source_dir}/ufs_model.fd/tests
FIXdir=${project_source_dir}/../fix
INPUTDATA_ROOT=${FIXdir}/UFS_WM
RT_COMPILER=${RT_COMPILER:-intel}
ATOL="1e-7"
source ${PATHRT}/detect_machine.sh
source ${PATHRT}/rt_utils.sh
source ${PATHRT}/default_vars.sh
source ${PATHRT}/tests/$TEST_NAME
source ${PATHRT}/atparse.bash

RTPWD=${RTPWD:-$FIXdir/test_base/${TEST_NAME}_${RT_COMPILER}}

if [[ ! -d ${RTPWD} ]]; then
  echo "Error: cannot find RTPWD, please check!"
  exit 1
fi  

# create test folder
RUNDIR=${project_binary_dir}/test/${TEST_NAME}
[[ -d ${RUNDIR} ]] && echo "Warning: remove old test folder!" && rm -rf ${RUNDIR}
mkdir -p ${RUNDIR}
cd ${RUNDIR}

# modify some env variables - reduce core usage
export ATM_compute_tasks=0
export ATM_io_tasks=1
export LND_tasks=6
export layout_x=1
export layout_y=1

# FV3 executable:
cp ${project_binary_dir}/ufs_model.fd/src/ufs_model.fd-build/ufs_model ./ufs_model

#set multiple input files
for i in ${FV3_RUN:-fv3_run.IN}
do
  atparse < ${PATHRT}/fv3_conf/${i} >> fv3_run
done

if [[ $DATM_CDEPS = 'true' ]] || [[ $FV3 = 'true' ]] || [[ $S2S = 'true' ]]; then
  if [[ $HAFS = 'false' ]] || [[ $FV3 = 'true' && $HAFS = 'true' ]]; then
    atparse < ${PATHRT}/parm/${INPUT_NML:-input.nml.IN} > input.nml
  fi
fi

atparse < ${PATHRT}/parm/${MODEL_CONFIGURE:-model_configure.IN} > model_configure

compute_petbounds_and_tasks

atparse < ${PATHRT}/parm/${UFS_CONFIGURE:-ufs.configure} > ufs.configure

# diag table
if [[ "Q${DIAG_TABLE:-}" != Q ]] ; then
  atparse < ${PATHRT}/parm/diag_table/${DIAG_TABLE} > diag_table
fi
# Field table
if [[ "Q${FIELD_TABLE:-}" != Q ]] ; then
  cp ${PATHRT}/parm/field_table/${FIELD_TABLE} field_table
fi

# Field Dictionary
cp ${PATHRT}/parm/fd_ufs.yaml fd_ufs.yaml

# Set up the run directory
source ./fv3_run

if [[ $DATM_CDEPS = 'true' ]]; then
  atparse < ${PATHRT}/parm/${DATM_IN_CONFIGURE:-datm_in} > datm_in
  atparse < ${PATHRT}/parm/${DATM_STREAM_CONFIGURE:-datm.streams.IN} > datm.streams
fi

# NoahMP table file
cp ${PATHRT}/parm/noahmptable.tbl noahmptable.tbl

# start runs
echo "Start ufs-cdeps-land model run with TASKS: ${TASKS}"
export MPIRUN=${MPIRUN:-`which mpiexec`}
${MPIRUN} -n ${TASKS} ./ufs_model

#
echo "Now check model output with ufs-wm baseline!"
for filename in ${LIST_FILES}; do
  if [[ -f ${RUNDIR}/${filename} ]] ; then
    echo "Baseline check with ${RTPWD}/${TEST_NAME}/${filename}"
    ${project_source_dir}/test/compare.py ${RUNDIR}/${filename} ${RTPWD}/${filename} ${ATOL}
  fi
done
