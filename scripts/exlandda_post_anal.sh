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

FILEDATE=${YYYY}${MM}${DD}.${HH}0000
for itile in {1..6}
do
  cp ${DATA_SHARE}/${FILEDATE}.sfc_data.tile${itile}.nc .
  cp ${DATA_SHARE}/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${itile}.nc .
done

#  convert back to vector, run model (all members) convert back to vector, run model (all members)
if [[ ${ATMOS_FORC} == "era5" ]]; then
  echo '************************************************'
  echo 'calling tile2vector' 

  cp ${PARMlandda}/templates/template.tile2vector tile2vector.namelist

  sed -i "s|FIXlandda|${FIXlandda}|g" tile2vector.namelist
  sed -i -e "s/XXYYYY/${YYYY}/g" tile2vector.namelist
  sed -i -e "s/XXMM/${MM}/g" tile2vector.namelist
  sed -i -e "s/XXDD/${DD}/g" tile2vector.namelist
  sed -i -e "s/XXHH/${HH}/g" tile2vector.namelist
  sed -i -e "s/MODEL_FORCING/${ATMOS_FORC}/g" vector2tile.namelist
  sed -i -e "s/XXRES/${RES}/g" tile2vector.namelist
  sed -i -e "s/XXTSTUB/${TSTUB}/g" tile2vector.namelist
  sed -i -e "s#XXTPATH#${TPATH}#g" tile2vector.namelist

  export pgm="vector2tile_converter.exe"
  . prep_step
  ${EXEClandda}/$pgm tile2vector.namelist >>$pgmout 2>errfile
  export err=$?; err_chk
  cp errfile errfile_tile2vector
  if [[ $err != 0 ]]; then
    echo "tile2vector failed"
    exit 10
  fi

  # save analysis restart
  cp -p ${DATA}/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc ${COMOUT}/ufs_land_restart.anal.${YYYY}-${MM}-${DD}_${HH}-00-00.nc

  echo '************************************************'
  echo 'running the forecast model' 
      
  # update model namelist 
  cp ${PARMlandda}/templates/template.ufs-noahMP.namelist.${ATMOS_FORC} ufs-land.namelist
  
  sed -i "s|FIXlandda|${FIXlandda}|g" ufs-land.namelist
  sed -i -e "s/XXYYYY/${YYYY}/g" ufs-land.namelist
  sed -i -e "s/XXMM/${MM}/g" ufs-land.namelist
  sed -i -e "s/XXDD/${DD}/g" ufs-land.namelist
  sed -i -e "s/XXHH/${HH}/g" ufs-land.namelist
  sed -i -e "s/XXFREQ/${FREQ}/g" ufs-land.namelist
  sed -i -e "s/XXRDD/${RDD}/g" ufs-land.namelist
  sed -i -e "s/XXRHH/${RHH}/g" ufs-land.namelist

  nt=$SLURM_NTASKS

  export pgm="ufsLand.exe"
  . prep_step
  ${MPIEXEC} -n 1 ${EXEClandda}/$pgm >>$pgmout 2>errfile
  export err=$?; err_chk
  cp errfile errfile_ufsLand
  if [[ $err != 0 ]]; then
    echo "ufsLand failed"
    exit 10
  fi

  cp -p ${DATA}/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc ${COMOUT}/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc

  # link restart for next cycle
  ln -nsf ${COMOUT}/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc ${DATA_RESTART}

#  convert back to UFS tile, run model (all members)
elif [[ ${ATMOS_FORC} == "gswp3" ]]; then  
  echo '************************************************'
  echo 'calling tile2tile' 

  cp ${PARMlandda}/templates/template.jedi2ufs jedi2ufs.namelist
   
  sed -i "s|FIXlandda|${FIXlandda}|g" jedi2ufs.namelist
  sed -i -e "s/XXYYYY/${YYYY}/g" jedi2ufs.namelist
  sed -i -e "s/XXMM/${MM}/g" jedi2ufs.namelist
  sed -i -e "s/XXDD/${DD}/g" jedi2ufs.namelist
  sed -i -e "s/XXHH/${HH}/g" jedi2ufs.namelist
  sed -i -e "s/MODEL_FORCING/${ATMOS_FORC}/g" jedi2ufs.namelist
  sed -i -e "s/XXRES/${RES}/g" jedi2ufs.namelist
  sed -i -e "s/XXTSTUB/${TSTUB}/g" jedi2ufs.namelist
  sed -i -e "s#XXTPATH#${TPATH}#g" jedi2ufs.namelist

  export pgm="tile2tile_converter.exe"
  . prep_step
  ${EXEClandda}/$pgm jedi2ufs.namelist >>$pgmout 2>errfile
  export err=$?; err_chk
  cp errfile errfile_tile2tile
  if [[ $err != 0 ]]; then
    echo "tile2tile failed"
    exit 10
  fi

  # save analysis restart
  for itile in {1..6}
  do
    cp -p ${DATA}/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${itile}.nc ${COMOUT}/ufs_land_restart.anal.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${itile}.nc
  done  
fi
