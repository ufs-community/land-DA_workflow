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

TPATH=${LANDDA_INPUTS}/forcing/${ATMOS_FORC}/orog_files/
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
MEM_MODL_OUTDIR=${COMOUT}/${mem_ens}
RSTRDIR=${MEM_WORKDIR}
JEDIWORKDIR=${WORKDIR}/mem000/jedi
FILEDATE=${YYYY}${MM}${DD}.${HH}0000
JEDI_STATICDIR=${JEDI_INSTALL}/jedi-bundle/fv3-jedi/test/Data
JEDI_EXECDIR=${JEDI_INSTALL}/build/bin
SAVE_INCR="YES"
KEEPJEDIDIR="YES"

cd $MEM_WORKDIR

# load modulefiles
BUILD_VERSION_FILE="${HOMElandda}/versions/build.ver_${MACHINE}"
if [ -e ${BUILD_VERSION_FILE} ]; then
  . ${BUILD_VERSION_FILE}
fi
module use modulefiles; module load modules.landda
MPIEXEC=`which mpiexec`

#SNOWDEPTHVAR=snwdph
YAML_DA=construct
GFSv17="NO"
B=30 # back ground error std for LETKFOI
cd $JEDIWORKDIR

################################################
# 3. DETERMINE REQUESTED JEDI TYPE, CONSTRUCT YAMLS
################################################

do_DA="YES"
do_HOFX="NO"

if [[ $do_DA == "NO" && $do_HOFX == "NO" ]]; then 
        echo "do_landDA:No obs found, not calling JEDI" 
        exit 0 
fi

# if yaml is specified by user, use that. Otherwise, build the yaml
if [[ $do_DA == "YES" ]]; then 

   if [[ $YAML_DA == "construct" ]];then  # construct the yaml
     cp ${PARMlandda}/jedi/${DAtype}.yaml ${JEDIWORKDIR}/letkf_land.yaml
     for obs in "${OBS_TYPES[@]}";
     do 
       cat ${PARMlandda}/jedi/${obs}.yaml >> letkf_land.yaml
     done
   else # use specified yaml 
     echo "Using user specified YAML: ${YAML_DA}"
     cp ${PARMlandda}/jedi/${YAML_DA} ${JEDIWORKDIR}/letkf_land.yaml
   fi

   sed -i -e "s/XXYYYY/${YYYY}/g" letkf_land.yaml
   sed -i -e "s/XXMM/${MM}/g" letkf_land.yaml
   sed -i -e "s/XXDD/${DD}/g" letkf_land.yaml
   sed -i -e "s/XXHH/${HH}/g" letkf_land.yaml

   sed -i -e "s/XXYYYP/${YYYP}/g" letkf_land.yaml
   sed -i -e "s/XXMP/${MP}/g" letkf_land.yaml
   sed -i -e "s/XXDP/${DP}/g" letkf_land.yaml
   sed -i -e "s/XXHP/${HP}/g" letkf_land.yaml

   sed -i -e "s/XXTSTUB/${TSTUB}/g" letkf_land.yaml
   sed -i -e "s#XXTPATH#${TPATH}#g" letkf_land.yaml
   sed -i -e "s/XXRES/${RES}/g" letkf_land.yaml
   RESP1=$((RES+1))
   sed -i -e "s/XXREP/${RESP1}/g" letkf_land.yaml

   sed -i -e "s/XXHOFX/false/g" letkf_land.yaml  # do DA
fi

if [[ $do_HOFX == "YES" ]]; then 

   if [[ $YAML_HOFX == "construct" ]];then  # construct the yaml
     cp ${PARMlandda}/jedi/${DAtype}.yaml ${JEDIWORKDIR}/hofx_land.yaml
     for obs in "${OBS_TYPES[@]}";
     do 
       cat ${PARMlandda}/jedi/${obs}.yaml >> hofx_land.yaml
     done
   else # use specified yaml 
     echo "Using user specified YAML: ${YAML_HOFX}"
     cp ${PARMlandda}/jedi/${YAML_HOFX} ${JEDIWORKDIR}/hofx_land.yaml
   fi

   sed -i -e "s/XXYYYY/${YYYY}/g" hofx_land.yaml
   sed -i -e "s/XXMM/${MM}/g" hofx_land.yaml
   sed -i -e "s/XXDD/${DD}/g" hofx_land.yaml
   sed -i -e "s/XXHH/${HH}/g" hofx_land.yaml

   sed -i -e "s/XXYYYP/${YYYP}/g" hofx_land.yaml
   sed -i -e "s/XXMP/${MP}/g" hofx_land.yaml
   sed -i -e "s/XXDP/${DP}/g" hofx_land.yaml
   sed -i -e "s/XXHP/${HP}/g" hofx_land.yaml

   sed -i -e "s#XXTPATH#${TPATH}#g" hofx_land.yaml
   sed -i -e "s/XXTSTUB/${TSTUB}/g" hofx_land.yaml
   sed -i -e "s/XXRES/${RES}/g" hofx_land.yaml
   RESP1=$((RES+1))
   sed -i -e "s/XXREP/${RESP1}/g" hofx_land.yaml

   sed -i -e "s/XXHOFX/true/g" hofx_land.yaml  # do HOFX

fi

if [[ "$GFSv17" == "NO" ]]; then
  cp ${PARMlandda}/jedi/gfs-land.yaml ${JEDIWORKDIR}/gfs-land.yaml
else
  cp ${JEDI_INSTALL}/jedi-bundle/fv3-jedi/test/Data/fieldmetadata/gfs_v17-land.yaml ${JEDIWORKDIR}/gfs-land.yaml
fi

################################################
# 4. CREATE BACKGROUND ENSEMBLE (LETKFOI)
################################################
################################################
# 5. RUN JEDI
################################################

if [[ ! -e Data ]]; then
    ln -s $JEDI_STATICDIR Data 
fi

echo 'do_landDA: calling fv3-jedi'

if [[ $do_DA == "YES" ]]; then
  export pgm="fv3jedi_letkf.x"
  . prep_step
  ${MPIEXEC} -n $NPROC_JEDI ${JEDI_EXECDIR}/$pgm letkf_land.yaml >>$pgmout 2>errfile
  export err=$?; err_chk
  cp errfile errfile_jedi_letkf
  if [[ $err != 0 ]]; then
    echo "JEDI DA failed"
    exit 10
  fi
fi 
if [[ $do_HOFX == "YES" ]]; then
  export pgm="fv3jedi_letkf.x"
  . prep_step
  ${MPIEXEC} -n $NPROC_JEDI ${JEDI_EXEC} hofx_land.yaml >>$pgmout 2>errfile
  export err=$?; err_chk
  cp errfile errfile_jedi_hofx
  if [[ $err != 0 ]]; then
    echo "JEDI hofx failed"
    exit 10
  fi
fi 

################################################
# 6. APPLY INCREMENT TO UFS RESTARTS 
################################################

if [[ $do_DA == "YES" ]]; then 

  if [[ $DAtype == "letkfoi_snow" ]]; then 

cat << EOF > apply_incr_nml
&noahmp_snow
 date_str=${YYYY}${MM}${DD}
 hour_str=$HH
 res=$RES
 frac_grid=$GFSv17
 orog_path="$TPATH"
 otype="$TSTUB"
/
EOF

    echo 'do_landDA: calling apply snow increment'

    export pgm="apply_incr.exe"
    . prep_step
    # (n=6) -> this is fixed, at one task per tile (with minor code change, could run on a single proc). 
    ${MPIEXEC} -n 6 ${EXEClandda}/$pgm >>$pgmout 2>errfile
    export err=$?; err_chk
    cp errfile errfile_apply_incr
    if [[ $err != 0 ]]; then
      echo "apply snow increment failed"
      exit 10
    fi

  fi

fi 

################################################
# 7. CLEAN UP
################################################

# keep increments
if [ $SAVE_INCR == "YES" ] && [ $do_DA == "YES" ]; then
   cp ${JEDIWORKDIR}/${FILEDATE}.xainc.sfc_data.tile*.nc  ${COMOUT}/DA/jedi_incr/
fi 

# clean up 
if [[ $KEEPJEDIDIR == "NO" ]]; then
   rm -rf ${JEDIWORKDIR} 
fi 
