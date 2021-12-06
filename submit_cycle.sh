#! /bin/sh -l
#SBATCH --job-name=offline_noahmp
#SBATCH --account=gsienkf
#SBATCH --qos=debug
#SBATCH --nodes=1
#SBATCH --tasks-per-node=6
#SBATCH --cpus-per-task=1
#SBATCH -t 00:10:00
#SBATCH -o log_noahmp.%j.log
#SBATCH -e err_noahmp.%j.err
#SBATCH --export=NONE

# set your directories
WORKDIR=/scratch2/BMC/gsienkf/Clara.Draper/workdir/ # temporary work dir
RSTRDIR=/scratch2/BMC/gsienkf/Clara.Draper/gerrit-hera/noahMP_driver/cycleOI/restarts # dir to save restarts

dates_per_job=20

######################################################
# shouldn't need to change anything below here

source cycle_mods_bash

# executables

CYCLEDIR=$(pwd)  # this directory
vec2tileexec=${CYCLEDIR}/vector2tile/vector2tile_converter.exe
LSMexec=${CYCLEDIR}/ufs_land_driver/ufsLand.exe 

analdate=${CYCLEDIR}/analdates.sh
incdate=${CYCLEDIR}/incdate.sh

logfile=${CYCLEDIR}/cycle.log
touch $logfile

if [[ -d $WORKDIR ]]; then 
  rm -rf $WORKDIR
fi 

mkdir $WORKDIR
cd $WORKDIR
ln -s $RSTRDIR ${WORKDIR}/restarts
ln -s ${CYCLEDIR}/noahmp_output ${WORKDIR}/noahmp_output 

# read in dates 
source ${analdate}

echo "***************************************" >> $logfile
echo "cycling from $startdate to $enddate" >> $logfile

thisdate=$startdate

date_count=0

while [ $date_count -lt $dates_per_job ]; do

    if [ $thisdate -ge $enddate ]; then 
        echo "All done, at date ${thisdate}"  >> $logfile
        cd $CYCLEDIR 
        rm -rf $WORKDIR
        exit 
    fi

    echo "starting $thisdate"  

    # substringing to get yr, mon, day, hr info
    export YYYY=`echo $thisdate | cut -c1-4`
    export MM=`echo $thisdate | cut -c5-6`
    export DD=`echo $thisdate | cut -c7-8`
    export HH=`echo $thisdate | cut -c9-10`

    # update model namelist 
    cp  ${CYCLEDIR}/template.ufs-noahMP.namelist.gswp3  ufs-land.namelist

    sed -i -e "s/XXYYYY/${YYYY}/g" ufs-land.namelist 
    sed -i -e "s/XXMM/${MM}/g" ufs-land.namelist
    sed -i -e "s/XXDD/${DD}/g" ufs-land.namelist
    sed -i -e "s/XXHH/${HH}/g" ufs-land.namelist
     
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

    # save background restart
    cp ${CYCLEDIR}/restarts/vector/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc ${CYCLEDIR}/restarts/vector/ufs_land_restart_back.${YYYY}-${MM}-${DD}_${HH}-00-00.nc

    # submit vec2tile 
    echo '************************************************'
    echo 'calling vector2tile' 
    $vec2tileexec vector2tile.namelist
    if [[ $? != 0 ]]; then
        echo "vec2tile failed"
        exit 
    fi

    # submit snow DA 

    # submit tile2vec
    echo '************************************************'
    echo 'calling tile2vector' 
    $vec2tileexec tile2vector.namelist
    if [[ $? != 0 ]]; then
        echo "tile2vector failed"
        exit 
    fi

    # submit model
    echo '************************************************'
    echo 'calling model' 
    $LSMexec
# no error codes on exit from model, check for restart below instead
#    if [[ $? != 0 ]]; then
#        echo "model failed"
#        exit 
#    fi

    if [[ -e restarts/vector/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc ]]; then 
       echo "Finished job number, ${date_count},for  date: ${thisdate}" >> $logfile
       echo "Deleting tile files" 
        if [[ ! $KEEPTILES ]]; then 
                rm $RSTRDIR/tile/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.tile*.nc
        fi 
    else 
       echo "Something is wrong, probably the model, exiting" 
       exit
    fi

    thisdate=`${incdate} $thisdate 24`
    date_count=$((date_count+1))

done

# resubmit
if [ $thisdate -lt $enddate ]; then
    echo "export startdate=${thisdate}" > ${analdate}
    echo "export enddate=${enddate}" >> ${analdate}
    cd ${CYCLEDIR}
    rm -rf ${WORKDIR}
    sbatch ${CYCLEDIR}/submit_cycle.sh
fi

