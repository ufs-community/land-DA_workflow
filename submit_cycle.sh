#!/bin/bash -l
#SBATCH --job-name=offline_noahmp
#SBATCH --account=gsienkf
#SBATCH --qos=debug
#SBATCH --nodes=1
#SBATCH --tasks-per-node=6
#SBATCH --cpus-per-task=1
#SBATCH -t 00:10:00
#SBATCH -o log_noahmp.%j.log
#SBATCH -e err_noahmp.%j.err

# experiment name 
exp_name=open_testing
open_loop=True # If "False" do DA.

# set your directories
export WORKDIR=/scratch2/BMC/gsienkf/Clara.Draper/workdir/ # temporary work dir
export OUTDIR=/scratch2/BMC/gsienkf/Clara.Draper/gerrit-hera/AZworkflow/${exp_name}/output/

dates_per_job=2

######################################################
# shouldn't need to change anything below here

SAVEDIR=${OUTDIR}/restarts # dir to save restarts
MODLDIR=${OUTDIR}/noahmp # dir to save noah-mp output

# create output directories if they do not already exist.
if [[ ! -e ${OUTDIR} ]]; then
    mkdir -p ${OUTDIR}/DA
    mkdir ${OUTDIR}/DA/IMSproc 
    mkdir ${OUTDIR}/DA/jedi_incr
    mkdir ${OUTDIR}/DA/logs
    mkdir ${OUTDIR}/DA/hofx
    mkdir ${OUTDIR}/restarts
    mkdir ${OUTDIR}/restarts/vector
    mkdir ${OUTDIR}/restarts/tile
    mkdir ${OUTDIR}/noahmp
fi 

source cycle_mods_bash

# executables

CYCLEDIR=$(pwd)  # this directory
vec2tileexec=${CYCLEDIR}/vector2tile/vector2tile_converter.exe
LSMexec=${CYCLEDIR}/ufs_land_driver/ufsLand.exe 
DAscript=${CYCLEDIR}/landDA_workflow/do_snowDA.sh 
export DADIR=${CYCLEDIR}/landDA_workflow/

analdate=${CYCLEDIR}/analdates.sh
incdate=${CYCLEDIR}/incdate.sh

logfile=${CYCLEDIR}/cycle.log
touch $logfile

# read in dates 
source ${analdate}

echo "***************************************" >> $logfile
echo "cycling from $STARTDATE to $ENDDATE" >> $logfile

# If there is no restart in experiment directory, copy from current directory

sYYYY=`echo $STARTDATE | cut -c1-4`
sMM=`echo $STARTDATE | cut -c5-6`
sDD=`echo $STARTDATE | cut -c7-8`
sHH=`echo $STARTDATE | cut -c9-10`

if [[ ! -e ${OUTDIR}/restarts/vector/ufs_land_restart_back.${sYYYY}-${sMM}-${sDD}_${sHH}-00-00.nc ]]; then

cp ./ufs_land_restart.${sYYYY}-${sMM}-${sDD}_${sHH}-00-00.nc ${OUTDIR}/restarts/vector/ufs_land_restart_back.${sYYYY}-${sMM}-${sDD}_${sHH}-00-00.nc

fi

THISDATE=$STARTDATE

date_count=0

while [ $date_count -lt $dates_per_job ]; do

    if [ $THISDATE -ge $ENDDATE ]; then 
        echo "All done, at date ${THISDATE}"  >> $logfile
        cd $CYCLEDIR 
        rm -rf $WORKDIR
        exit  
    fi

    echo "starting $THISDATE"  

    # create temporary workdir
    if [[ -d $WORKDIR ]]; then 
      rm -rf $WORKDIR
    fi 

    mkdir $WORKDIR
    cd $WORKDIR
    ln -s ${MODLDIR} ${WORKDIR}/noahmp_output 

    mkdir ${WORKDIR}/restarts
    mkdir ${WORKDIR}/restarts/tile
    mkdir ${WORKDIR}/restarts/vector

    # substringing to get yr, mon, day, hr info
    export YYYY=`echo $THISDATE | cut -c1-4`
    export MM=`echo $THISDATE | cut -c5-6`
    export DD=`echo $THISDATE | cut -c7-8`
    export HH=`echo $THISDATE | cut -c9-10`

    # copy initial restart
    cp $SAVEDIR/vector/ufs_land_restart_back.${YYYY}-${MM}-${DD}_${HH}-00-00.nc $WORKDIR/restarts/vector/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc

    # update model namelist 
    cp  ${CYCLEDIR}/template.ufs-noahMP.namelist.gdas  ufs-land.namelist

    sed -i -e "s/XXYYYY/${YYYY}/g" ufs-land.namelist 
    sed -i -e "s/XXMM/${MM}/g" ufs-land.namelist
    sed -i -e "s/XXDD/${DD}/g" ufs-land.namelist
    sed -i -e "s/XXHH/${HH}/g" ufs-land.namelist
     
    if [ $open_loop == "False" ]; then  # do DA

        # update vec2tile and tile2vec namelists
        cp  ${CYCLEDIR}/template.vector2tile vector2tile.namelist

        sed -i -e "s/XXYYYY/${YYYY}/g" vector2tile.namelist
        sed -i -e "s/XXMM/${MM}/g" vector2tile.namelist
        sed -i -e "s/XXDD/${DD}/g" vector2tile.namelist
        sed -i -e "s/XXHH/${HH}/g" vector2tile.namelist

        cp  ${CYCLEDIR}/template.tile2vector tile2vector.namelist

        sed -i -e "s/XXYYYY/${YYYY}/g" tile2vector.namelist
        sed -i -e "s/XXMM/${MM}/g" tile2vector.namelist
        sed -i -e "s/XXDD/${DD}/g" tile2vector.namelist
        sed -i -e "s/XXHH/${HH}/g" tile2vector.namelist

        # submit vec2tile 
        echo '************************************************'
        echo 'calling vector2tile' 
        $vec2tileexec vector2tile.namelist
        if [[ $? != 0 ]]; then
            echo "vec2tile failed"
            exit 
        fi
        # add coupler.res file
        cres_file=${WORKDIR}/restarts/tile/${YYYY}${MM}${DD}.${HH}0000.coupler.res
        cp  ${CYCLEDIR}/template.coupler.res $cres_file

        sed -i -e "s/XXYYYY/${YYYY}/g" $cres_file
        sed -i -e "s/XXMM/${MM}/g" $cres_file
        sed -i -e "s/XXDD/${DD}/g" $cres_file

        # submit snow DA 
        echo '************************************************'
        echo 'calling snow DA'
        export THISDATE
        $DAscript
        if [[ $? != 0 ]]; then
            echo "land DA script failed"
            exit
        fi  # submit tile2vec

        echo '************************************************'
        echo 'calling tile2vector' 
        $vec2tileexec tile2vector.namelist
        if [[ $? != 0 ]]; then
            echo "tile2vector failed"
            exit 
        fi

        # save analysis restart
        cp ${WORKDIR}/restarts/vector/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc ${SAVEDIR}/vector/ufs_land_restart_anal.${YYYY}-${MM}-${DD}_${HH}-00-00.nc

    fi # DA step

    # submit model
    echo '************************************************'
    echo 'calling model' 
    $LSMexec
# no error codes on exit from model, check for restart below instead
#    if [[ $? != 0 ]]; then
#        echo "model failed"
#        exit 
#    fi

    NEXTDATE=`${incdate} $THISDATE 24`
    export YYYY=`echo $NEXTDATE | cut -c1-4`
    export MM=`echo $NEXTDATE | cut -c5-6`
    export DD=`echo $NEXTDATE | cut -c7-8`
    export HH=`echo $NEXTDATE | cut -c9-10`

    if [[ -e ${WORKDIR}/restarts/vector/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc ]]; then 
       cp ${WORKDIR}/restarts/vector/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc ${SAVEDIR}/vector/ufs_land_restart_back.${YYYY}-${MM}-${DD}_${HH}-00-00.nc
       echo "Finished job number, ${date_count},for  date: ${THISDATE}" >> $logfile
    else 
       echo "Something is wrong, probably the model, exiting" 
       exit
    fi

    THISDATE=`${incdate} $THISDATE 24`
    date_count=$((date_count+1))

done

# resubmit
if [ $THISDATE -lt $ENDDATE ]; then
    echo "export STARTDATE=${THISDATE}" > ${analdate}
    echo "export ENDDATE=${ENDDATE}" >> ${analdate}
    cd ${CYCLEDIR}
    rm -rf ${WORKDIR}
    sbatch ${CYCLEDIR}/submit_cycle.sh
fi

