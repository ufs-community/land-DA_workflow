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

MACHINE_ID=${MACHINE}
TPATH=${LANDDA_INPUTS}/forcing/${ATMOS_FORC}/orog_files/
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
mem_ens="mem000"

MEM_WORKDIR=${WORKDIR}/${mem_ens}
MEM_MODL_OUTDIR=${COMOUT}/${mem_ens}
RSTRDIR=${MEM_WORKDIR}
FILEDATE=${YYYY}${MM}${DD}.${HH}0000
SAVE_INCR="YES"
FREQ=$((${FCSTHR}*3600))
RDD=$((${FCSTHR}/24))
RHH=$((${FCSTHR}%24))

cd $MEM_WORKDIR

# load modulefiles
BUILD_VERSION_FILE="${HOMElandda}/versions/build.ver_${MACHINE}"
if [ -e ${BUILD_VERSION_FILE} ]; then
  . ${BUILD_VERSION_FILE}
fi
module use modulefiles; module load modules.landda
MPIEXEC=`which mpiexec`
MPIRUN=${MPIRUN:-`which mpiexec`}

#SNOWDEPTHVAR=snwdph

cd $MEM_WORKDIR

#  convert back to vector, run model (all members) convert back to vector, run model (all members)
if [[ $do_jedi == "YES" && ${ATMOS_FORC} == "era5" ]]; then
    echo '************************************************'
    echo 'calling tile2vector' 

    cp  ${HOMElandda}/parm/templates/template.tile2vector tile2vector.namelist

    sed -i "s|LANDDA_INPUTS|${LANDDA_INPUTS}|g" tile2vector.namelist
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
    mkdir -p ${MEM_MODL_OUTDIR}/restarts/vector
    cp ${MEM_WORKDIR}/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc ${MEM_MODL_OUTDIR}/restarts/vector/ufs_land_restart_anal.${YYYY}-${MM}-${DD}_${HH}-00-00.nc
fi

#  convert back to UFS tile, run model (all members)
if [[ $do_jedi == "YES" && ${ATMOS_FORC} == "gswp3" ]]; then  
    echo '************************************************'
    echo 'calling tile2tile' 

    cp ${HOMElandda}/parm/templates/template.jedi2ufs jedi2ufs.namelist
     
    sed -i "s|LANDDA_INPUTS|${LANDDA_INPUTS}|g" jedi2ufs.namelist
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
    mkdir -p ${MEM_MODL_OUTDIR}/restarts/tile
    for tile in 1 2 3 4 5 6
    do
        cp ${MEM_WORKDIR}/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${tile}.nc ${MEM_MODL_OUTDIR}/restarts/tile/ufs_land_restart_anal.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${tile}.nc    
        cp ${MEM_WORKDIR}/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${tile}.nc ${MEM_MODL_OUTDIR}/restarts/tile/ufs.cpld.lnd.out.${YYYY}-${MM}-${DD}-00000.tile${tile}.nc
    done  
fi


#jkimmmm
############################
# run the forecast model

if [[ $do_jedi == "YES" && ${ATMOS_FORC} == "era5" ]]; then 
    echo '************************************************'
    echo 'running the forecast model' 
	
    # update model namelist 
    cp  ${HOMElandda}/parm/templates/template.ufs-noahMP.namelist.${ATMOS_FORC}  ufs-land.namelist
    
    sed -i "s|LANDDA_INPUTS|${LANDDA_INPUTS}|g" ufs-land.namelist
    sed -i -e "s/XXYYYY/${YYYY}/g" ufs-land.namelist
    sed -i -e "s/XXMM/${MM}/g" ufs-land.namelist
    sed -i -e "s/XXDD/${DD}/g" ufs-land.namelist
    sed -i -e "s/XXHH/${HH}/g" ufs-land.namelist
    sed -i -e "s/XXFREQ/${FREQ}/g" ufs-land.namelist
    sed -i -e "s/XXRDD/${RDD}/g" ufs-land.namelist
    sed -i -e "s/XXRHH/${RHH}/g" ufs-land.namelist

    # submit model
    echo $MEM_WORKDIR

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
fi 
# no error codes on exit from model, check for restart below instead

if [[ $do_jedi == "YES" && ${ATMOS_FORC} == "gswp3" ]]; then
    
    echo '************************************************'
    echo 'running the forecast model' 

    TEST_NAME=datm_cdeps_lnd_gswp3
    TEST_NAME_RST=datm_cdeps_lnd_gswp3_rst
    PATHRT=${HOMElandda}/sorc/ufs_model.fd/tests
    RT_COMPILER=${RT_COMPILER:-intel}
    ATOL="1e-7"

    cp $HOMElandda/$TEST_NAME_RST ${PATHRT}/tests/$TEST_NAME_RST 
    source ${PATHRT}/rt_utils.sh
    source ${PATHRT}/default_vars.sh
    source ${PATHRT}/tests/$TEST_NAME_RST
    source ${PATHRT}/atparse.bash

    BL_DATE=20230816
    RTPWD=${RTPWD:-${LANDDA_INPUTS}/NEMSfv3gfs/develop-${BL_DATE}/INTEL/${TEST_NAME}}
    INPUTDATA_ROOT=${INPUTDATA_ROOT:-${LANDDA_INPUTS}/NEMSfv3gfs/input-data-20221101}

    echo "RTPWD= $RTPWD"
    echo "INPUTDATA_ROOT= $INPUTDATA_ROOT"

    if [[ ! -d ${INPUTDATA_ROOT} ]] || [[ ! -d ${RTPWD} ]]; then
	echo "Error: cannot find either folder for INPUTDATA_ROOT or RTPWD, please check!"
	exit 1
    fi

    # create run folder
    RUNDIR=${MEM_MODL_OUTDIR}/noahmp/${TEST_NAME_RST}
    [[ -d ${RUNDIR} ]] && echo "Warning: remove old run folder!" && rm -rf ${RUNDIR}
    mkdir -p ${RUNDIR}
    cd ${RUNDIR}

    echo "NoahMP run dir= $RUNDIR"

    # modify some env variables - reduce core usage
    export ATM_compute_tasks=0
    export ATM_io_tasks=1
    export LND_tasks=6
    export layout_x=1
    export layout_y=1

    # FV3 executable:
#    cp ${EXEClandda}/ufs_model ./ufs_model 
    cp ${HOMElandda}/fv3_run ./fv3_run

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
    source ./fv3_run

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
    ${MPIRUN} -n ${TASKS} ${EXEClandda}/$pgm >>$pgmout 2>errfile
    export err=$?; err_chk
    cp errfile errfile_ufs_model
    if [[ $err != 0 ]]; then
      echo "ufs_model failed"
      exit 10
    fi
fi

# no error codes on exit from model, check for restart below instead

############################
# check model ouput (all members)

if [[ ${ATMOS_FORC} == "era5" ]]; then
    if [[ -e ${MEM_WORKDIR}/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc ]]; then
	cp ${MEM_WORKDIR}/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc ${MEM_MODL_OUTDIR}/restarts/vector/ufs_land_restart_back.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc
    fi
fi

if [[ ${ATMOS_FORC} == "gswp3" ]]; then
  for tile in 1 2 3 4 5 6
  do
    cp ${COMOUT}/${mem_ens}/noahmp/${TEST_NAME_RST}/ufs.cpld.lnd.out.${nYYYY}-${nMM}-${nDD}-00000.tile${tile}.nc ${MEM_MODL_OUTDIR}/restarts/tile/ufs_land_restart_back.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.tile${tile}.nc
  done
fi
