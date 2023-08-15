#!/bin/bash
set -e
################################################
# pass arguments
project_binary_dir=$1
project_source_dir=$2

#
echo ${project_binary_dir}
echo ${project_source_dir}

#
export MACHINE_ID=${MACHINE_ID:-linux}
TEST_NAME=datm_cdeps_lnd_gswp3
PATHRT=${project_source_dir}/ufs-weather-model/tests
RT_COMPILER=${RT_COMPILER:-intel}
ATOL="1e-7"
source ${PATHRT}/detect_machine.sh
source ${PATHRT}/rt_utils.sh
source ${PATHRT}/default_vars.sh
source ${PATHRT}/tests/$TEST_NAME
source ${PATHRT}/atparse.bash

# Set inputdata location for each machines
echo "MACHINE_ID: $MACHINE_ID"
if [[ $MACHINE_ID = orion.* ]]; then
  DISKNM=/work/noaa/nems/emc.nemspara/RT
elif [[ $MACHINE_ID = hera.* ]]; then
  DISKNM=/scratch1/NCEPDEV/nems/emc.nemspara/RT
else
  echo "Warning: MACHINE_ID is default, users will have to define INPUTDATA_ROOT and RTPWD by themselives"
fi
source ${PATHRT}/bl_date.conf
RTPWD=${RTPWD:-$DISKNM/NEMSfv3gfs/develop-${BL_DATE}/${RT_COMPILER^^}}
INPUTDATA_ROOT=${INPUTDATA_ROOT:-$DISKNM/NEMSfv3gfs/input-data-20221101}

if [[ ! -d ${INPUTDATA_ROOT} ]] || [[ ! -d ${RTPWD} ]]; then
echo "Error: cannot find either folder for INPUTDATA_ROOT or RTPWD, please check!"
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
cp ${project_binary_dir}/ufs-weather-model/src/ufs-weather-model-build/ufs_model ./ufs_model

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

atparse < ${PATHRT}/parm/${NEMS_CONFIGURE:-nems.configure} > nems.configure

# diag table
if [[ "Q${DIAG_TABLE:-}" != Q ]] ; then
  atparse < ${PATHRT}/parm/diag_table/${DIAG_TABLE} > diag_table
fi
# Field table
if [[ "Q${FIELD_TABLE:-}" != Q ]] ; then
  cp ${PATHRT}/parm/field_table/${FIELD_TABLE} field_table
fi

# Field Dictionary
cp ${PATHRT}/parm/fd_nems.yaml fd_nems.yaml

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
    ${project_source_dir}/test/compare.py ${RUNDIR}/${filename} ${RTPWD}/${TEST_NAME}/${filename} ${ATOL}
  fi
done
