#!/bin/bash
#SBATCH --job-name=land_da_wflow
#SBATCH --account=epic
#SBATCH --qos=debug
#SBATCH --nodes=1
#SBATCH --tasks-per-node=6
#SBATCH --cpus-per-task=1
#SBATCH -t 00:30:00
#SBATCH -o log_landda_wflow.%j.log
#SBATCH -e err_landda_wflow.%j.err


export MACHINE="orion"
export SCHED="slurm"
export ACCOUNT="epic"
export FORCING="era5"

if [ "${MACHINE}" = "hera" ]; then
  export EXP_BASEDIR="/scratch2/NAGAPE/epic/{USER}/landda_test"
  export JEDI_INSTALL="/scratch2/NAGAPE/epic/UFS_Land-DA/jedi_skylabv7.0"
elif [ "${MACHINE}" = "orion" ]; then
  export EXP_BASEDIR="/work/noaa/epic/{USER}/landda_test"
  export JEDI_INSTALL="/work/noaa/epic/UFS_Land-DA_Dev/jedi_v7"
fi

export RES="96"
export FCSTHR="24"
export NPROCS_ANALYSIS="6"
export NPROCS_FORECAST="6"
export OBSDIR=""
export OBSDIR_SUBDIR=""
export OBS_TYPES="GHCN"
export DAtype="letkfoi_snow"
export SNOWDEPTHVAR="snwdph"
export TSTUB="oro_C96.mx100"
export NET="landda"
export envir="test"
export model_ver="v1.2.1"
export HOMElandda="${EXP_BASEDIR}/land-DA_workflow"
export PTMP="${EXP_BASEDIR}/ptmp"
export COMROOT="${PTMP}/${envir}/com"
export DATAROOT="${PTMP}/${envir}/tmp"
export KEEPDATA="YES"
export WORKDIR="${EXP_BASEDIR}/workdir/run_&FORCING;"
export LOGDIR="${EXP_BASEDIR}/com/output/logs"
export PATHRT="${EXP_BASEDIR}"
export SLASH_ENSMEM_SUBDIR=""
export ATMOS_FORC="${FORCING}"
export NPROC_JEDI="${NPROCS_ANALYSIS}"

if [ "${FORCING}" = "era5" ]; then
  export PDY="20191221"
  export cyc="00"
  export PTIME="2019122000"
  export NTIME="2019122200"
elif [ "${FORCING}" = "gswp3" ]; then
  export PDY="20000103"
  export cyc="00"
  export PTIME="2000010200"
  export NTIME="2000010400"
fi

# Call J-job scripts
#
echo " ... PREP_EXP running ... "
${HOMElandda}/parm/task_load_modules_run_jjob.sh "prep_exp" "${HOMElandda}" "${MACHINE}"
export err=$?
if [ $err = 0 ]; then
  echo " === PREP_EXP completed successfully === "
else
  echo " ERROR: PREP_EXP failed !!! "
  exit 1
fi

echo " ... PREP_OBS running ... "
${HOMElandda}/parm/task_load_modules_run_jjob.sh "prep_obs" "${HOMElandda}" "${MACHINE}"
export err=$?
if [ $err = 0 ]; then
  echo " === PREP_OBS completed successfully === "
else
  echo " ERROR: PREP_OBS failed !!! "
  exit 2
fi

echo " ... ANALYSIS running ... "
${HOMElandda}/parm/task_load_modules_run_jjob.sh "analysis" "${HOMElandda}" "${MACHINE}"
export err=$?
if [ $err = 0 ]; then
  echo " === Task ANALYSIS completed successfully === "
else
  echo " ERROR: ANALYSIS failed !!! "
  exit 4
fi

echo " ... FORECAST running ... "
${HOMElandda}/parm/task_load_modules_run_jjob.sh "forecast" "${HOMElandda}" "${MACHINE}"
export err=$?
if [ $err = 0 ]; then
  echo " === Task FORECAST completed successfully === "
else
  echo " ERROR: FORECAST failed !!! "
  exit 5
fi

