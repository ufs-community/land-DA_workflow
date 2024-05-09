#!/bin/sh

set -ex

############################
# copy restarts to workdir, convert to UFS tile for DA (all members) 

if [[ ${EXP_NAME} == "openloop" ]]; then
    do_jedi="NO"
else
    do_jedi="YES"
    SAVE_TILE="YES"
fi

echo ${FIXlandda}, ${ATMOS_FORC}
TPATH=${FIXlandda}/forcing/${ATMOS_FORC}/orog_files/
YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}
YYYP=${PTIME:0:4}
MP=${PTIME:4:2}
DP=${PTIME:6:2}
HP=${PTIME:8:2}
mem_ens="mem000" 

MEM_WORKDIR=${WORKDIR}/${mem_ens}
JEDIWORKDIR=${WORKDIR}/mem000/jedi
FILEDATE=${YYYY}${MM}${DD}.${HH}0000

mkdir -p ${MEM_WORKDIR}
mkdir -p $MEM_WORKDIR/modulefiles
cp ${HOMElandda}/modulefiles/build_${MACHINE}_intel.lua $MEM_WORKDIR/modulefiles/modules.landda.lua
cd $MEM_WORKDIR

# load modulefiles
BUILD_VERSION_FILE="${HOMElandda}/versions/build.ver_${MACHINE}"
if [ -e ${BUILD_VERSION_FILE} ]; then
  . ${BUILD_VERSION_FILE}
fi

module use modulefiles; module load modules.landda

if [[ $do_jedi == "YES" ]]; then

  if [[ $ATMOS_FORC == "era5" ]]; then
    # vector2tile for DA
    # copy restarts into work directory
    rst_in=${COMOUT}/${mem_ens}/restarts/vector/ufs_land_restart_back.${YYYY}-${MM}-${DD}_${HH}-00-00.nc
    if [[ ! -e ${rst_in} ]]; then
      rst_in=${FIXlandda}/restarts/${ATMOS_FORC}/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc
    fi
    rst_out=${MEM_WORKDIR}/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc
    cp ${rst_in} ${rst_out}

    echo '************************************************'
    echo 'calling vector2tile' 

    export MEM_WORKDIR

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
      exit
    fi 
  elif [[ $ATMOS_FORC == "gswp3" ]]; then
    # tile2tile for DA
    echo '************************************************'
    echo 'calling tile2tile'    

    export MEM_WORKDIR
   
    # copy restarts into work directory
    for tile in 1 2 3 4 5 6
    do
      rst_in=${COMOUT}/${mem_ens}/restarts/tile/ufs_land_restart_back.${YYYY}-${MM}-${DD}_${HH}-00-00.nc
      if [[ ! -e ${rst_in} ]]; then  
        rst_in=${FIXlandda}/restarts/${ATMOS_FORC}/ufs.cpld.lnd.out.${YYYY}-${MM}-${DD}-00000.tile${tile}.nc
      fi
      rst_out=${MEM_WORKDIR}/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${tile}.nc
      cp ${rst_in} ${rst_out}
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
      exit 
    fi
  fi

  if [[ ! -e $JEDIWORKDIR ]]; then
    mkdir -p $JEDIWORKDIR
  fi    
  cd $JEDIWORKDIR

  if  [[ $SAVE_TILE == "YES" ]]; then
    for tile in 1 2 3 4 5 6
    do
      cp ${MEM_WORKDIR}/${FILEDATE}.sfc_data.tile${tile}.nc  ${MEM_WORKDIR}/${FILEDATE}.sfc_data_back.tile${tile}.nc
    done
  fi

  #stage restarts for applying JEDI update (files will get directly updated)
  for tile in 1 2 3 4 5 6
  do
    ln -fs ${MEM_WORKDIR}/${FILEDATE}.sfc_data.tile${tile}.nc ${JEDIWORKDIR}/${FILEDATE}.sfc_data.tile${tile}.nc
  done

  cres_file=${JEDIWORKDIR}/${FILEDATE}.coupler.res    

  if [[ -e  ${MEM_WORKDIR}/${FILEDATE}.coupler.res ]]; then
    ln -sf ${MEM_WORKDIR}/${FILEDATE}.coupler.res $cres_file
  else #  if not present, need to create coupler.res for JEDI
    cp ${PARMlandda}/templates/template.coupler.res $cres_file

    sed -i -e "s/XXYYYY/${YYYY}/g" $cres_file
    sed -i -e "s/XXMM/${MM}/g" $cres_file
    sed -i -e "s/XXDD/${DD}/g" $cres_file
    sed -i -e "s/XXHH/${HH}/g" $cres_file
    sed -i -e "s/XXYYYP/${YYYP}/g" $cres_file
    sed -i -e "s/XXMP/${MP}/g" $cres_file
    sed -i -e "s/XXDP/${DP}/g" $cres_file
    sed -i -e "s/XXHP/${HP}/g" $cres_file	
  fi    
fi # do_jedi setup

