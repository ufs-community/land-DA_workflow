#!/bin/sh

set -xue

MACHINE_ID=${MACHINE}
TPATH=${FIXlandda}/forcing/${ATMOS_FORC}/orog_files/
YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}
YYYYMMDD=${PDY}
nYYYY=${NTIME:0:4}
nMM=${NTIME:4:2}
nDD=${NTIME:6:2}
nHH=${NTIME:8:2}

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

  # Set model_configure
  cp ${PARMlandda}/templates/template.model_configure model_configure
  sed -i -e "s/XXYYYY/${YYYY}/g" model_configure
  sed -i -e "s/XXMM/${MM}/g" model_configure
  sed -i -e "s/XXDD/${DD}/g" model_configure
  sed -i -e "s/XXHH/${HH}/g" model_configure
  sed -i -e "s/XXFCSTHR/${FCSTHR}/g" model_configure

  compute_petbounds_and_tasks

  atparse < ${PATHRT}/parm/${UFS_CONFIGURE:-ufs.configure} > ufs.configure

  # set diag table
  if [[ "Q${DIAG_TABLE:-}" != Q ]] ; then
    cp ${PARMlandda}/templates/template.diag_table diag_table
    sed -i -e "s/XXYYYYMMDD/${YYYYMMDD}/g" diag_table
    sed -i -e "s/XXYYYY/${YYYY}/g" diag_table
    sed -i -e "s/XXMM/${MM}/g" diag_table
    sed -i -e "s/XXDD/${DD}/g" diag_table
    sed -i -e "s/XXHH/${HH}/g" diag_table
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

  # Retrieve input files for restart
  # NoahMP restart files
  for itile in {1..6}
  do
    ln -nsf ${COMIN}/ufs_land_restart.anal.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${itile}.nc RESTART/ufs.cpld.lnd.out.${YYYY}-${MM}-${DD}-00000.tile${itile}.nc
  done

  # CMEPS restart and pointer files
  rfile1="ufs.cpld.cpl.r.${YYYY}-${MM}-${DD}-00000.nc"
  if [[ -e "${COMINm1}/${rfile1}" ]]; then
    cp "${COMINm1}/${rfile1}" RESTART/.
  elif [[ -e "${WARMSTART_DIR}/${rfile1}" ]]; then
    cp "${WARMSTART_DIR}/${rfile1}" RESTART/.
  else
    cp ${FIXlandda}/restarts/gswp3/${rfile1} RESTART/.
  fi
  ls -1 "RESTART/${rfile1}">rpointer.cpl

  # CDEPS restart and pointer files
  rfile2="ufs.cpld.datm.r.${YYYY}-${MM}-${DD}-00000.nc"
  if [[ -e "${COMINm1}/${rfile2}" ]]; then
    cp "${COMINm1}/${rfile2}" RESTART/.
  elif [[ -e "${WARMSTART_DIR}/${rfile2}" ]]; then
    cp "${WARMSTART_DIR}/${rfile2}" RESTART/.
  else
    cp ${FIXlandda}/restarts/gswp3/${rfile2} RESTART/.
  fi
  ls -1 "RESTART/${rfile2}">rpointer.atm

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

  # copy model ouput to COM
  for itile in {1..6}
  do
    cp -p ${DATA}/ufs.cpld.lnd.out.${nYYYY}-${nMM}-${nDD}-00000.tile${itile}.nc ${COMOUT}/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.tile${itile}.nc
  done
  cp -p ${DATA}/ufs.cpld.datm.r.${nYYYY}-${nMM}-${nDD}-00000.nc ${COMOUT}
  cp -p ${DATA}/RESTART/ufs.cpld.cpl.r.${nYYYY}-${nMM}-${nDD}-00000.nc ${COMOUT}

  # link restart for next cycle
  for itile in {1..6}
  do
    ln -nsf ${COMOUT}/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.tile${itile}.nc ${DATA_RESTART}
  done
fi
