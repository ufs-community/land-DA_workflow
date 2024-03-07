#!/bin/bash
#SBATCH --job-name=land_da_wflow
#SBATCH --account=nems
#SBATCH --qos=debug
#SBATCH --nodes=1
#SBATCH --tasks-per-node=6
#SBATCH --cpus-per-task=1
#SBATCH -t 00:30:00
#SBATCH -o log_landda_wflow.%j.log
#SBATCH -e err_landda_wflow.%j.err


export MACHINE="hera"
export ACCOUNT="nems"
export FORCING="gswp3"
export NET="landda"
export model_ver="v1.2.1"

if [ "${MACHINE}" = "hera" ]; then
  export EXP_BASEDIR="/scratch2/NAGAPE/epic/{USER}/landda_nonrocoto"
  export JEDI_INSTALL="/scratch2/NAGAPE/epic/UFS_Land-DA/jedi"
  export LANDDA_INPUTS="/scratch2/NAGAPE/epic/UFS_Land-DA/inputs"
elif [ "${MACHINE}" = "orion" ]; then
  export EXP_BASEDIR="/work/noaa/epic/{USER}/landda_nonrocoto"
  export JEDI_INSTALL="/work/noaa/epic/UFS_Land-DA/jedi"
  export LANDDA_INPUTS="/work/noaa/epic/UFS_Land-DA/inputs"
fi

export RES="96"
export FCSTHR="24"
export NPROCS_ANA="6"
export NPROCS_FCST="6"
export OBS_TYPES="GHCN"
export fv3bundle_vn="psl_develop"
export DAtype="letkfoi_snow"
export SNOWDEPTHVAR="snwdph"
export TSTUB="oro_C96.mx100"
export WORKDIR="${EXP_BASEDIR}/workdir/run_&FORCING;"
export CYCLEDIR="${EXP_BASEDIR}/land-DA_workflow"
export EXECdir="${CYCLEDIR}/exec"
export OUTDIR="${EXP_BASEDIR}/com/${NET}/${model_ver}/run_${FORCING}"
export LOGDIR="${EXP_BASEDIR}/com/output/logs"
export PATHRT="${EXP_BASEDIR}"

export ATMOS_FORC="${FORCING}"
export NPROC_JEDI="${NPROCS_ANA}"

if [ "${FORCING}" = "era5" ]; then
  export CTIME="2019122100"
  export PTIME="2019122000"
  export NTIME="2019122200"
elif [ "${FORCING}" = "gswp3" ]; then
  export CTIME="2000010300"
  export PTIME="2000010200"
  export NTIME="2000010400"
fi

# Call J-job scripts
#
echo " ... PREP_EXP running ... "
${CYCLEDIR}/jobs/JLANDDA_PREP_EXP
export err=$?
if [ $err = 0 ]; then
  echo " === PREP_EXP completed successfully === "
else
  echo " ERROR: PREP_EXP failed !!! "
  exit 1
fi

echo " ... PREP_OBS running ... "
${CYCLEDIR}/jobs/JLANDDA_PREP_OBS
export err=$?
if [ $err = 0 ]; then
  echo " === PREP_OBS completed successfully === "
else
  echo " ERROR: PREP_OBS failed !!! "
  exit 2
fi

echo " ... PREP_BMAT running ... "
${CYCLEDIR}/jobs/JLANDDA_PREP_BMAT
export err=$?
if [ $err = 0 ]; then
  echo " === PREP_BMAT completed successfully === "
else
  echo " ERROR: PREP_BMAT failed !!! "
  exit 3
fi

echo " ... RUN_ANA running ... "
${CYCLEDIR}/jobs/JLANDDA_RUN_ANA
export err=$?
if [ $err = 0 ]; then
  echo " === RUN_ANA completed successfully === "
else
  echo " ERROR: RUN_ANA failed !!! "
  exit 4
fi

echo " ... RUN_FCST running ... "
${CYCLEDIR}/jobs/JLANDDA_RUN_FCST
export err=$?
if [ $err = 0 ]; then
  echo " === RUN_FCST completed successfully === "
else
  echo " ERROR: RUN_FCST failed !!! "
  exit 5
fi

