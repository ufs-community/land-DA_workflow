#!/bin/sh

set -xue

TPATH=${FIXlandda}/forcing/${ATMOS_FORC}/orog_files/
YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}
YYYP=${PTIME:0:4}
MP=${PTIME:4:2}
DP=${PTIME:6:2}
HP=${PTIME:8:2}

FILEDATE=${YYYY}${MM}${DD}.${HH}0000

mkdir -p modulefiles
cp ${HOMElandda}/modulefiles/build_${MACHINE}_intel.lua $DATA/modulefiles/modules.landda.lua

# load modulefiles
BUILD_VERSION_FILE="${HOMElandda}/versions/build.ver_${MACHINE}"
if [ -e ${BUILD_VERSION_FILE} ]; then
  . ${BUILD_VERSION_FILE}
fi
module use modulefiles; module load modules.landda

if [[ $ATMOS_FORC == "era5" ]]; then
  # vector2tile for DA
  # copy restarts into work directory
  rst_fn="ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc"
  if [[ -e ${DATA_RESTART}/${rst_fn} ]]; then
    cp ${DATA_RESTART}/${rst_fn} .      
  elif [[ -e ${WARMSTART_DIR}/${rst_fn} ]]; then
    cp ${WARMSTART_DIR}/${rst_fn} .
  else
    echo "Initial restart file does not exist"
    exit 11
  fi
  cp -p ${rst_fn} ${DATA_SHARE}

  echo '************************************************'
  echo 'calling vector2tile' 

  # update vec2tile and tile2vec namelists
  cp  ${PARMlandda}/templates/template.vector2tile vector2tile.namelist

  sed -i "s|FIXlandda|${FIXlandda}|g" vector2tile.namelist
  sed -i -e "s/XXYYYY/${YYYY}/g" vector2tile.namelist
  sed -i -e "s/XXMM/${MM}/g" vector2tile.namelist
  sed -i -e "s/XXDD/${DD}/g" vector2tile.namelist
  sed -i -e "s/XXHH/${HH}/g" vector2tile.namelist
  sed -i -e "s/XXHH/${HH}/g" vector2tile.namelist
  sed -i -e "s/MODEL_FORCING/${ATMOS_FORC}/g" vector2tile.namelist
  sed -i -e "s/XXRES/${RES}/g" vector2tile.namelist
  sed -i -e "s/XXTSTUB/${TSTUB}/g" vector2tile.namelist
  sed -i -e "s#XXTPATH#${TPATH}#g" vector2tile.namelist

  # submit vec2tile 
  echo '************************************************'
  echo 'calling vector2tile' 

  export pgm="vector2tile_converter.exe"
  . prep_step
  ${EXEClandda}/$pgm vector2tile.namelist >>$pgmout 2>errfile
  cp errfile errfile_vector2tile
  export err=$?; err_chk
  if [[ $err != 0 ]]; then
    echo "vec2tile failed"
    exit 12
  fi 


elif [[ $ATMOS_FORC == "gswp3" ]]; then
  # tile2tile for DA
  echo '************************************************'
  echo 'calling tile2tile'    
 
  # copy restarts into work directory
  for itile in {1..6}
  do
    rst_fn="ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${itile}.nc"
    if [[ -e ${DATA_RESTART}/${rst_fn} ]]; then
      cp ${DATA_RESTART}/${rst_fn} .
    elif [[ -e ${WARMSTART_DIR}/${rst_fn} ]]; then
      cp ${WARMSTART_DIR}/${rst_fn} .
    else
      echo "Initial restart files do not exist"
      exit 21
    fi
    # copy restart to data share dir for post_anal
    cp -p ${rst_fn} ${DATA_SHARE}
  done

  # update tile2tile namelist
  cp  ${PARMlandda}/templates/template.ufs2jedi ufs2jedi.namelist

  sed -i "s|FIXlandda|${FIXlandda}|g" ufs2jedi.namelist
  sed -i -e "s/XXYYYY/${YYYY}/g" ufs2jedi.namelist
  sed -i -e "s/XXMM/${MM}/g" ufs2jedi.namelist
  sed -i -e "s/XXDD/${DD}/g" ufs2jedi.namelist
  sed -i -e "s/XXHH/${HH}/g" ufs2jedi.namelist
  sed -i -e "s/XXHH/${HH}/g" ufs2jedi.namelist
  sed -i -e "s/MODEL_FORCING/${ATMOS_FORC}/g" ufs2jedi.namelist
  sed -i -e "s/XXRES/${RES}/g" ufs2jedi.namelist
  sed -i -e "s/XXTSTUB/${TSTUB}/g" ufs2jedi.namelist
  sed -i -e "s#XXTPATH#${TPATH}#g" ufs2jedi.namelist

  # submit tile2tile
  export pgm="tile2tile_converter.exe"
  . prep_step
  ${EXEClandda}/$pgm ufs2jedi.namelist >>$pgmout 2>errfile
  cp errfile errfile_tile2tile
  export err=$?; err_chk
  if [[ $err != 0 ]]; then
    echo "tile2tile failed"
    exit 22 
  fi

  #stage restarts for applying JEDI update to intermediate directory
  for itile in {1..6}
  do
    cp -p ${DATA}/${FILEDATE}.sfc_data.tile${itile}.nc ${DATA_SHARE}/${FILEDATE}.sfc_data.tile${itile}.nc
  done
fi

