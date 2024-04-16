#!/bin/sh

set -ex

############################
# copy restarts to workdir, convert to UFS tile for DA (all members) 

if [[ ${EXP_NAME} == "openloop" ]]; then
    do_jedi="NO"
else
    do_jedi="YES"
    SAVE_TILE="YES"
    LANDDADIR=${HOMElandda}/sorc/DA_update
fi

TPATH=${LANDDA_INPUTS}/forcing/${ATMOS_FORC}/orog_files/
YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}

mem_ens="mem000" 

MEM_WORKDIR=${WORKDIR}/${mem_ens}
MEM_MODL_OUTDIR=${COMOUT}/${mem_ens}
RSTRDIR=${MEM_WORKDIR}
JEDIWORKDIR=${WORKDIR}/mem000/jedi
FILEDATE=${YYYY}${MM}${DD}.${HH}0000

cd $MEM_WORKDIR

# load modulefiles
BUILD_VERSION_FILE="${HOMElandda}/versions/build.ver_${MACHINE}"
if [ -e ${BUILD_VERSION_FILE} ]; then
  . ${BUILD_VERSION_FILE}
fi
module use modulefiles; module load modules.landda
PYTHON=$(/usr/bin/which python)

#SNOWDEPTHVAR=snwdph
YAML_DA=construct
GFSv17="NO"
B=30 # back ground error std for LETKFOI
cd $JEDIWORKDIR

################################################
# 4. CREATE BACKGROUND ENSEMBLE (LETKFOI)
################################################

if [[ ${DAtype} == "letkfoi_snow" ]]; then

    JEDI_EXEC="fv3jedi_letkf.x"

    if [ $GFSv17 == "YES" ]; then
        SNOWDEPTHVAR="snodl"
        # field overwrite file with GFSv17 variables.
        cp ${PARMlandda}/jedi/gfs-land-v17.yaml ${JEDIWORKDIR}/gfs-land-v17.yaml
    else
        SNOWDEPTHVAR="snwdph"
    fi
    # FOR LETKFOI, CREATE THE PSEUDO-ENSEMBLE
    for ens in pos neg
    do
        if [ -e $JEDIWORKDIR/mem_${ens} ]; then
                rm -r $JEDIWORKDIR/mem_${ens}
        fi
        mkdir -p $JEDIWORKDIR/mem_${ens}
        for tile in 1 2 3 4 5 6
        do
        cp ${JEDIWORKDIR}/${FILEDATE}.sfc_data.tile${tile}.nc  ${JEDIWORKDIR}/mem_${ens}/${FILEDATE}.sfc_data.tile${tile}.nc
        done
        cp ${JEDIWORKDIR}/${FILEDATE}.coupler.res ${JEDIWORKDIR}/mem_${ens}/${FILEDATE}.coupler.res
    done

    echo 'do_landDA: calling create ensemble'

    # using ioda mods to get a python version with netCDF4
    ${PYTHON} ${LANDDADIR}/letkf_create_ens.py $FILEDATE $SNOWDEPTHVAR $B
    if [[ $? != 0 ]]; then
        echo "letkf create failed"
        exit 10
    fi

fi
