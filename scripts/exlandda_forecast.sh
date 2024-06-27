#!/bin/sh

set -xue

MACHINE_ID=${MACHINE}

YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}
YYYYMMDD=${PDY}
nYYYY=${NTIME:0:4}
nMM=${NTIME:4:2}
nDD=${NTIME:6:2}
nHH=${NTIME:8:2}

case $MACHINE in
  "hera")
    RUN_CMD="srun"
    ;;
  "orion")
    RUN_CMD="srun"
    ;;
  "hercules")
    RUN_CMD="srun"
    ;;
  *)
    RUN_CMD=`which mpiexec`
    ;;
esac

#  convert back to UFS tile, run model (all members)
if [[ ${ATMOS_FORC} == "gswp3" ]]; then  

  echo '************************************************'
  echo 'running the forecast model' 

  PATHRT=${HOMElandda}/sorc/ufs_model.fd/tests
  source ${PATHRT}/rt_utils.sh
  source ${PATHRT}/default_vars.sh

  # modify some env variables - reduce core usage
  export ATM_compute_tasks=0
  export ATM_io_tasks=1
  export LND_tasks=6
  export layout_x=1
  export layout_y=1

  cp ${PARMlandda}/templates/template.input.nml input.nml
  cp ${PARMlandda}/templates/template.ufs.configure ufs.configure
  cp ${PARMlandda}/templates/template.datm_in datm_in
  cp ${PARMlandda}/templates/template.datm.streams datm.streams
  cp ${PARMlandda}/templates/template.noahmptable.tbl noahmptable.tbl
  cp ${PARMlandda}/templates/template.fd_ufs.yaml fd_ufs.yaml

  # Set model_configure
  cp ${PARMlandda}/templates/template.model_configure model_configure
  sed -i -e "s/XXYYYY/${YYYY}/g" model_configure
  sed -i -e "s/XXMM/${MM}/g" model_configure
  sed -i -e "s/XXDD/${DD}/g" model_configure
  sed -i -e "s/XXHH/${HH}/g" model_configure
  sed -i -e "s/XXFCSTHR/${FCSTHR}/g" model_configure

  # set diag table
  cp ${PARMlandda}/templates/template.diag_table diag_table
  sed -i -e "s/XXYYYYMMDD/${YYYYMMDD}/g" diag_table
  sed -i -e "s/XXYYYY/${YYYY}/g" diag_table
  sed -i -e "s/XXMM/${MM}/g" diag_table
  sed -i -e "s/XXDD/${DD}/g" diag_table
  sed -i -e "s/XXHH/${HH}/g" diag_table

  # Set up the run directory
  mkdir -p RESTART

  # NoahMP restart files
  for itile in {1..6}
  do
    ln -nsf ${COMIN}/ufs_land_restart.anal.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${itile}.nc RESTART/ufs.cpld.lnd.out.${YYYY}-${MM}-${DD}-00000.tile${itile}.nc
  done

  # CMEPS restart and pointer files
  rfile1="ufs.cpld.cpl.r.${YYYY}-${MM}-${DD}-00000.nc"
  if [[ -e "${COMINm1}/${rfile1}" ]]; then
    ln -nsf "${COMINm1}/${rfile1}" RESTART/.
  elif [[ -e "${WARMSTART_DIR}/${rfile1}" ]]; then
    ln -nsf "${WARMSTART_DIR}/${rfile1}" RESTART/.
  else
    ln -nsf ${FIXlandda}/restarts/${ATMOS_FORC}/${rfile1} RESTART/.
  fi
  ls -1 "RESTART/${rfile1}">rpointer.cpl

  # CDEPS restart and pointer files
  rfile2="ufs.cpld.datm.r.${YYYY}-${MM}-${DD}-00000.nc"
  if [[ -e "${COMINm1}/${rfile2}" ]]; then
    ln -nsf "${COMINm1}/${rfile2}" RESTART/.
  elif [[ -e "${WARMSTART_DIR}/${rfile2}" ]]; then
    ln -nsf "${WARMSTART_DIR}/${rfile2}" RESTART/.
  else
    ln -nsf ${FIXlandda}/restarts/${ATMOS_FORC}/${rfile2} RESTART/.
  fi
  ls -1 "RESTART/${rfile2}">rpointer.atm

  mkdir -p INPUT
  cd INPUT
  ln -nsf ${FIXlandda}/DATM_input_data/${ATMOS_FORC}/* .
  for itile in {1..6}
  do
    ln -nsf ${FIXlandda}/NOAHMP_IC/ufs-land_C${RES}_init_fields.tile${itile}.nc C${RES}.initial.tile${itile}.nc
    ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}.maximum_snow_albedo.tile${itile}.nc .
    ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}.slope_type.tile${itile}.nc .
    ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}.soil_type.tile${itile}.nc .
    ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}.soil_color.tile${itile}.nc .
    ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}.substrate_temperature.tile${itile}.nc .
    ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}.vegetation_greenness.tile${itile}.nc .
    ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}.vegetation_type.tile${itile}.nc .
    ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/oro_C${RES}.mx100.tile${itile}.nc oro_data.tile${itile}.nc
    ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}_grid.tile${itile}.nc .
    ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/grid_spec.nc C${RES}_mosaic.nc
  done
  cd -

  # start runs
  echo "Start ufs-cdeps-land model run with TASKS: ${NPROCS_FORECAST}"
  export pgm="ufs_model"
  . prep_step
  ${RUN_CMD} -n ${NPROCS_FORECAST} ${EXEClandda}/$pgm >>$pgmout 2>errfile
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
