#!/bin/bash -le 
#SBATCH --job-name=offline_noahmp
#SBATCH --account=gsienkf
#SBATCH --qos=debug
#SBATCH --nodes=1
#SBATCH --tasks-per-node=6
#SBATCH --cpus-per-task=1
#SBATCH -t 00:10:00
#SBATCH -o log_noahmp.%j.log
#SBATCH -e err_noahmp.%j.err

############################
# load config file 

if [[ $# -gt 0 ]]; then 
    config_file=$1
else
    config_file=settings
fi

echo "reading cycle settings from $config_file"
source $config_file

KEEPWORKDIR="YES"

############################
# load modules 

source cycle_mods_bash
export CYCLEDIR=$(pwd) 

############################
# set executables

vec2tileexec=${CYCLEDIR}/vector2tile/vector2tile_converter.exe
LSMexec=${CYCLEDIR}/ufs-land-driver/run/ufsLand.exe 
DADIR=${CYCLEDIR}/DA_update/
DAscript=${DADIR}/do_landDA.sh

analdate=${CYCLEDIR}/analdates.sh
incdate=${CYCLEDIR}/incdate.sh

############################
# read in dates  

source ${analdate}

logfile=${CYCLEDIR}/cycle.log
touch $logfile
echo "***************************************" >> $logfile
echo "cycling from $STARTDATE to $ENDDATE" >> $logfile

sYYYY=`echo $STARTDATE | cut -c1-4`
sMM=`echo $STARTDATE | cut -c5-6`
sDD=`echo $STARTDATE | cut -c7-8`
sHH=`echo $STARTDATE | cut -c9-10`

# compute the restart frequency, run_days and run_hours
FREQ=$(( 3600 * $FCSTHR )) 
RDD=$(( $FCSTHR / 24 )) 
RHH=$(( $FCSTHR % 24 )) 

############################
# set up directories

#workdir
if [[ ! -e ${WORKDIR} ]]; then 
    mkdir ${WORKDIR}
fi

#outdir for model
if [[ ! -e ${OUTDIR}/modl ]]; then
    mkdir -p  ${OUTDIR}/modl
fi 

###############################
# create ensemble dirs and copy in ICS if needed
echo 'ensemble size, '$ensemble_size 

n_ens=1
while [ $n_ens -le $ensemble_size ]; do
    echo 'in ensemble loop, '$n_ens

    if [ $ensemble_size == 1 ]; then 
        mem_ens="" 
    else 
        mem_ens="mem`printf %03i $n_ens`"
    fi 

    # ensemble workdir
    MEM_WORKDIR=${WORKDIR}/${mem_ens}
    if [[ ! -e $MEM_WORKDIR ]]; then
      mkdir $MEM_WORKDIR
    fi

    # workdir subdirs
    if [[ ! -e ${MEM_WORKDIR}/restarts ]]; then
        mkdir ${MEM_WORKDIR}/restarts
        mkdir ${MEM_WORKDIR}/restarts/tile
        mkdir ${MEM_WORKDIR}/restarts/vector
    fi 

    # ensemble outdir (model only)
    MEM_MODL_OUTDIR=${OUTDIR}/modl/${mem_ens}
    if [[ ! -e $MEM_MODL_OUTDIR ]]; then  #ensemble outdir
        mkdir -p $MEM_MODL_OUTDIR
    fi 
    
    # outdir subdirs
    if [[ ! -e ${MEM_MODL_OUTDIR}/restarts/ ]]; then  # subdirectories
        mkdir -p ${MEM_MODL_OUTDIR}/restarts/vector/ 
        mkdir ${MEM_MODL_OUTDIR}/restarts/tile/
        mkdir -p ${MEM_MODL_OUTDIR}/noahmp/
        ln -s ${MEM_MODL_OUTDIR}/noahmp/ ${MEM_WORKDIR}/noahmp_output 
    fi

    # copy ICS into restarts, if needed 
    rst_in=${ICSDIR}/output/modl/${mem_ens}/restarts/vector/ufs_land_restart.${sYYYY}-${sMM}-${sDD}_${sHH}-00-00.nc
    rst_in_single=${ICSDIR}/output/modl/restarts/vector/ufs_land_restart.${sYYYY}-${sMM}-${sDD}_${sHH}-00-00.nc
    rst_out=${MEM_MODL_OUTDIR}/restarts/vector/ufs_land_restart_back.${sYYYY}-${sMM}-${sDD}_${sHH}-00-00.nc
 
    # if restart not in experiment out directory, copy the restarts from the ICSDIR
    if [[ ! -e ${rst_out} ]]; then 
        echo "Looking for ICS: ${rst_in}"
        # if ensemble of restarts exists in ICSDIR, use these. Otherwise, use single restart.
        if [[ -e ${rst_in} ]]; then
           echo "ICS found, copying" 
           cp ${rst_in} ${rst_out}
        else  # use non-ensemble restart
           echo "ICS not found. Checking for ensemble started from single member: ${rst_in_single}"
           if [[ -e ${rst_in_single} ]]; then
               echo "ICS found, copying" 
               cp ${rst_in_single} ${rst_out}
           else 
               echo "ICS not found. Exiting" 
               exit 10 
           fi 
        fi 
    fi 

    n_ens=$((n_ens+1))

done # n_ens < ensemble_size

############################
# loop over time steps

THISDATE=$STARTDATE
date_count=0

while [ $date_count -lt $dates_per_job ]; do

    if [ $THISDATE -ge $ENDDATE ]; then 
        echo "All done, at date ${THISDATE}"  >> $logfile
        cd $CYCLEDIR 
        if [ $KEEPWORKDIR == "NO" ];   then 
            rm -rf $WORKDIR
        fi
        exit  
    fi

    echo "starting $THISDATE"  

    # substringing to get yr, mon, day, hr info
    YYYY=`echo $THISDATE | cut -c1-4`
    MM=`echo $THISDATE | cut -c5-6`
    DD=`echo $THISDATE | cut -c7-8`
    HH=`echo $THISDATE | cut -c9-10`

    # substringing to get yr, mon, day, hr info for previous cycle
    PREVDATE=`${incdate} $THISDATE -6`
    YYYP=`echo $PREVDATE | cut -c1-4`
    MP=`echo $PREVDATE | cut -c5-6`
    DP=`echo $PREVDATE | cut -c7-8`
    HP=`echo $PREVDATE | cut -c9-10`

    ############################
    # copy in restarts

    n_ens=1
    while [ $n_ens -le $ensemble_size ]; do

        if [ $ensemble_size == 1 ]; then 
            mem_ens="" 
        else 
            mem_ens="mem`printf %03i $n_ens`"
        fi 

        MEM_WORKDIR=${WORKDIR}/${mem_ens}

        # copy restarts into work directory
        rst_in=${MEM_MODL_OUTDIR}/restarts/vector/ufs_land_restart_back.${YYYY}-${MM}-${DD}_${HH}-00-00.nc 
        rst_out=${MEM_WORKDIR}/restarts/vector/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc
        cp $rst_in $rst_out 

        n_ens=$((n_ens+1))

    done # n_ens < ensemble_size

    ############################
    # call JEDI 

    this_config=DA_config$HH
    DA_config=${!this_config}
    if [ $DA_config == "openloop" ]; then do_jedi="NO" ; else do_jedi="YES" ; fi 
    echo "entering JEDI" $do_jedi

    if [ $do_jedi == "YES" ]; then  # do DA

        cd ${WORKDIR}

        # CSDtodo - do for every ensemble member
        # update vec2tile and tile2vec namelists
        cp  ${CYCLEDIR}/template.vector2tile vector2tile.namelist

        sed -i -e "s/XXYYYY/${YYYY}/g" vector2tile.namelist
        sed -i -e "s/XXMM/${MM}/g" vector2tile.namelist
        sed -i -e "s/XXDD/${DD}/g" vector2tile.namelist
        sed -i -e "s/XXHH/${HH}/g" vector2tile.namelist
        sed -i -e "s/XXHH/${HH}/g" vector2tile.namelist
        sed -i -e "s/XXRES/${RES}/g" vector2tile.namelist
        sed -i -e "s/XXTSTUB/${TSTUB}/g" vector2tile.namelist
        sed -i -e "s#XXTPATH#${TPATH}#g" vector2tile.namelist

        cp  ${CYCLEDIR}/template.tile2vector tile2vector.namelist

        sed -i -e "s/XXYYYY/${YYYY}/g" tile2vector.namelist
        sed -i -e "s/XXMM/${MM}/g" tile2vector.namelist
        sed -i -e "s/XXDD/${DD}/g" tile2vector.namelist
        sed -i -e "s/XXHH/${HH}/g" tile2vector.namelist
        sed -i -e "s/XXRES/${RES}/g" tile2vector.namelist
        sed -i -e "s/XXTSTUB/${TSTUB}/g" tile2vector.namelist
        sed -i -e "s#XXTPATH#${TPATH}#g" tile2vector.namelist

        # submit vec2tile 
        echo '************************************************'
        echo 'calling vector2tile' 
        $vec2tileexec vector2tile.namelist
        if [[ $? != 0 ]]; then
            echo "vec2tile failed"
            exit 
        fi

        # CSDtodo - call once
        # submit snow DA 
        echo '************************************************'
        echo 'calling snow DA'
        export THISDATE
        $DAscript ${CYCLEDIR}/$DA_config
        if [[ $? != 0 ]]; then
            echo "land DA script failed"
            exit
        fi   
        # CSDtodo - every ensemble member 
        echo '************************************************'
        echo 'calling tile2vector' 
        $vec2tileexec tile2vector.namelist
        if [[ $? != 0 ]]; then
            echo "tile2vector failed"
            exit 
        fi

        # CSDtodo - every ensemble member 
        # save analysis restart
        cp ${WORKDIR}/restarts/vector/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc ${OUTDIR}/modl/restarts/vector/ufs_land_restart_anal.${YYYY}-${MM}-${DD}_${HH}-00-00.nc

    fi # DA step

    ############################
    # run the forecast model

    NEXTDATE=`${incdate} $THISDATE $FCSTHR`
    nYYYY=`echo $NEXTDATE | cut -c1-4`
    nMM=`echo $NEXTDATE | cut -c5-6`
    nDD=`echo $NEXTDATE | cut -c7-8`
    nHH=`echo $NEXTDATE | cut -c9-10`

    # loop over ensemble members

    n_ens=1
    while [ $n_ens -le $ensemble_size ]; do

        if [ $ensemble_size == 1 ]; then 
            mem_ens="" 
        else 
            mem_ens="mem`printf %03i $n_ens`"
        fi 

        MEM_WORKDIR=${WORKDIR}/${mem_ens}/
        MEM_MODL_OUTDIR=${OUTDIR}/modl/${mem_ens}/ # for model only

        cd $MEM_WORKDIR

        # update model namelist 
     
        if [ $ensemble_size == 1 ]; then
            cp  ${CYCLEDIR}/template.ufs-noahMP.namelist.${atmos_forc}  ufs-land.namelist
        else
            cp ${CYCLEDIR}/template.ufs-noahMP.namelist.ens.${atmos_forc} ufs-land.namelist
        fi

        sed -i -e "s/XXYYYY/${YYYY}/g" ufs-land.namelist
        sed -i -e "s/XXMM/${MM}/g" ufs-land.namelist
        sed -i -e "s/XXDD/${DD}/g" ufs-land.namelist
        sed -i -e "s/XXHH/${HH}/g" ufs-land.namelist
        sed -i -e "s/XXFREQ/${FREQ}/g" ufs-land.namelist
        sed -i -e "s/XXRDD/${RDD}/g" ufs-land.namelist
        sed -i -e "s/XXRHH/${RHH}/g" ufs-land.namelist
        NN="`printf %02i $n_ens`" # ensemble number  # update this to 03 (in forcing file)
        sed -i -e "s/XXMEM/${NN}/g" ufs-land.namelist

        # submit model
        echo '************************************************'
        echo 'calling model' 
        echo $MEM_WORKDIR
        $LSMexec

    # no error codes on exit from model, check for restart below instead
    #    if [[ $? != 0 ]]; then
    #        echo "model failed"
    #        exit 
    #    fi

        if [[ -e ${MEM_WORKDIR}/restarts/vector/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc ]]; then 
           cp ${MEM_WORKDIR}/restarts/vector/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc ${MEM_MODL_OUTDIR}/restarts/vector/ufs_land_restart_back.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc
        else 
           echo "Something is wrong, probably the model, exiting" 
           exit
        fi

        n_ens=$((n_ens+1))
    done # n_ens < ensemble_size

    echo "Finished job number, ${date_count},for  date: ${THISDATE}" >> $logfile

    THISDATE=$NEXTDATE
    date_count=$((date_count+1))

done #  date_count -lt dates_per_job


############################
# resubmit script 

if [ $THISDATE -lt $ENDDATE ]; then
    echo "STARTDATE=${THISDATE}" > ${analdate}
    echo "ENDDATE=${ENDDATE}" >> ${analdate}
    cd ${CYCLEDIR}
    sbatch ${CYCLEDIR}/submit_cycle.sh $1
fi

