#!/bin/sh

set -xue

############################
# copy restarts to workdir, convert to UFS tile for DA (all members)

MACHINE_ID=${MACHINE}
TPATH=${FIXlandda}/forcing/${ATMOS_FORC}/orog_files/
YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}
YYYP=${PTIME:0:4}
MP=${PTIME:4:2}
DP=${PTIME:6:2}
HP=${PTIME:8:2}
nYYYY=${NTIME:0:4}
nMM=${NTIME:4:2}
nDD=${NTIME:6:2}
nHH=${NTIME:8:2}

FREQ=$((${FCSTHR}*3600))
RDD=$((${FCSTHR}/24))
RHH=$((${FCSTHR}%24))

# load modulefiles
BUILD_VERSION_FILE="${HOMElandda}/versions/build.ver_${MACHINE}"
if [ -e ${BUILD_VERSION_FILE} ]; then
  . ${BUILD_VERSION_FILE}
fi
mkdir -p modulefiles
cp ${HOMElandda}/modulefiles/build_${MACHINE}_intel.lua $DATA/modulefiles/modules.landda.lua
module use modulefiles; module load modules.landda

MPIEXEC=`which mpiexec`

#  convert back to UFS tile, run model (all members)
if [[ ${ATMOS_FORC} == "gswp3" ]]; then  

  echo '************************************************'
  echo 'running the forecast model' 

  TEST_NAME=datm_cdeps_lnd_gswp3
  TEST_NAME_RST=datm_cdeps_lnd_gswp3_rst
  PATHRT=${HOMElandda}/sorc/ufs_model.fd/tests
  RT_COMPILER=${RT_COMPILER:-intel}
  ATOL="1e-7"

  cp $PARMlandda/$TEST_NAME_RST ${PATHRT}/tests/$TEST_NAME_RST 
  source ${PATHRT}/rt_utils.sh
  source ${PATHRT}/default_vars.sh
  source ${PATHRT}/tests/$TEST_NAME_RST
  source ${PATHRT}/atparse.bash

  BL_DATE=20230816
  RTPWD=${RTPWD:-${FIXlandda}/NEMSfv3gfs/develop-${BL_DATE}/INTEL/${TEST_NAME}}
  INPUTDATA_ROOT=${INPUTDATA_ROOT:-${FIXlandda}/NEMSfv3gfs/input-data-20221101}

  echo "RTPWD= $RTPWD"
  echo "INPUTDATA_ROOT= $INPUTDATA_ROOT"

  if [[ ! -d ${INPUTDATA_ROOT} ]] || [[ ! -d ${RTPWD} ]]; then
    echo "Error: cannot find either folder for INPUTDATA_ROOT or RTPWD, please check!"
    exit 1
  fi

  # modify some env variables - reduce core usage
  export ATM_compute_tasks=0
  export ATM_io_tasks=1
  export LND_tasks=6
  export layout_x=1
  export layout_y=1

  # FV3 executable: 
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
  mkdir -p RESTART INPUT
  cd INPUT
  ln -nsf ${FIXlandda}/UFS_WM/DATM_GSWP3_input_data/* .
  cd -

  SUFFIX=${RT_SUFFIX}
  # restart
  if [ $WARM_START = .true. ]; then
    # NoahMP restart files
    cp ${COMOUT}/RESTART/tile/ufs.cpld.lnd.out.${RESTART_FILE_SUFFIX_SECS}.tile*.nc RESTART/.

    # CMEPS restart and pointer files
    RFILE1=ufs.cpld.cpl.r.${RESTART_FILE_SUFFIX_SECS}.nc
    cp ${FIXlandda}/restarts/gswp3/${RFILE1} RESTART/.
    ls -1 "RESTART/${RFILE1}">rpointer.cpl

    # CDEPS restart and pointer files
    RFILE2=ufs.cpld.datm.r.${RESTART_FILE_SUFFIX_SECS}.nc
    cp ${FIXlandda}/restarts/gswp3/${RFILE2} RESTART/.
    ls -1 "RESTART/${RFILE2}">rpointer.atm
  fi

  cd INPUT
  ln -nsf ${FIXlandda}/UFS_WM/NOAHMP_IC/ufs-land_C96_init_fields.tile1.nc C96.initial.tile1.nc
  ln -nsf ${FIXlandda}/UFS_WM/NOAHMP_IC/ufs-land_C96_init_fields.tile2.nc C96.initial.tile2.nc
  ln -nsf ${FIXlandda}/UFS_WM/NOAHMP_IC/ufs-land_C96_init_fields.tile3.nc C96.initial.tile3.nc
  ln -nsf ${FIXlandda}/UFS_WM/NOAHMP_IC/ufs-land_C96_init_fields.tile4.nc C96.initial.tile4.nc
  ln -nsf ${FIXlandda}/UFS_WM/NOAHMP_IC/ufs-land_C96_init_fields.tile5.nc C96.initial.tile5.nc
  ln -nsf ${FIXlandda}/UFS_WM/NOAHMP_IC/ufs-land_C96_init_fields.tile6.nc C96.initial.tile6.nc
  ln -nsf ${FIXlandda}/UFS_WM/FV3_fix_tiled/C96/C96.maximum_snow_albedo.tile*.nc .
  ln -nsf ${FIXlandda}/UFS_WM/FV3_fix_tiled/C96/C96.slope_type.tile*.nc .
  ln -nsf ${FIXlandda}/UFS_WM/FV3_fix_tiled/C96/C96.soil_type.tile*.nc .
  ln -nsf ${FIXlandda}/UFS_WM/FV3_fix_tiled/C96/C96.soil_color.tile*.nc .
  ln -nsf ${FIXlandda}/UFS_WM/FV3_fix_tiled/C96/C96.substrate_temperature.tile*.nc .
  ln -nsf ${FIXlandda}/UFS_WM/FV3_fix_tiled/C96/C96.vegetation_greenness.tile*.nc .
  ln -nsf ${FIXlandda}/UFS_WM/FV3_fix_tiled/C96/C96.vegetation_type.tile*.nc .
  ln -nsf ${FIXlandda}/UFS_WM/FV3_fix_tiled/C96/oro_C96.mx100.tile1.nc oro_data.tile1.nc
  ln -nsf ${FIXlandda}/UFS_WM/FV3_fix_tiled/C96/oro_C96.mx100.tile2.nc oro_data.tile2.nc
  ln -nsf ${FIXlandda}/UFS_WM/FV3_fix_tiled/C96/oro_C96.mx100.tile3.nc oro_data.tile3.nc
  ln -nsf ${FIXlandda}/UFS_WM/FV3_fix_tiled/C96/oro_C96.mx100.tile4.nc oro_data.tile4.nc
  ln -nsf ${FIXlandda}/UFS_WM/FV3_fix_tiled/C96/oro_C96.mx100.tile5.nc oro_data.tile5.nc
  ln -nsf ${FIXlandda}/UFS_WM/FV3_fix_tiled/C96/oro_C96.mx100.tile6.nc oro_data.tile6.nc
  ln -nsf ${FIXlandda}/UFS_WM/FV3_input_data/INPUT/C96_grid.tile*.nc .
  ln -nsf ${FIXlandda}/UFS_WM/FV3_input_data/INPUT/grid_spec.nc C96_mosaic.nc
  cd -

  if [[ $DATM_CDEPS = 'true' ]]; then
    atparse < ${PATHRT}/parm/${DATM_IN_CONFIGURE:-datm_in.IN} > datm_in
    atparse < ${PATHRT}/parm/${DATM_STREAM_CONFIGURE:-datm.streams.IN} > datm.streams
  fi

  # NoahMP table file
  cp ${PATHRT}/parm/noahmptable.tbl noahmptable.tbl

  # start runs
  echo "Start ufs-cdeps-land model run with TASKS: ${TASKS}"
  export pgm="ufs_model"
  . prep_step
  ${MPIEXEC} -n ${TASKS} ${EXEClandda}/$pgm >>$pgmout 2>errfile
  export err=$?; err_chk
  cp errfile errfile_ufs_model
  if [[ $err != 0 ]]; then
    echo "ufs_model failed"
    exit 10
  fi
fi

############################
# check model ouput (all members)
if [[ ${ATMOS_FORC} == "era5" ]]; then
  if [[ -e ${DATA}/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc ]]; then
    cp -p ${DATA}/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc ${COMOUT}/RESTART/vector/ufs_land_restart_back.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc
  fi
elif [[ ${ATMOS_FORC} == "gswp3" ]]; then
  for tile in 1 2 3 4 5 6
  do
    cp -p ${DATA}/ufs.cpld.lnd.out.${nYYYY}-${nMM}-${nDD}-00000.tile${tile}.nc ${COMOUT}/RESTART/tile/ufs_land_restart_back.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.tile${tile}.nc
  done
fi
