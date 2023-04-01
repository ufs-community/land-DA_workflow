#!/bin/bash  
#SBATCH --job-name=offline_noahmp
#SBATCH --account=nems
#SBATCH --qos=debug
#SBATCH --nodes=1
#SBATCH --tasks-per-node=6
#SBATCH --cpus-per-task=1
#SBATCH -t 00:06:00
#SBATCH -o log_noahmp.%j.log
#SBATCH -e err_noahmp.%j.err

############################
# loop over time steps

source $analdate 

THISDATE=$STARTDATE
date_count=0

while [ $date_count -lt $cycles_per_job ]; do

    if [ $THISDATE -ge $ENDDATE ]; then 
        echo "All done, at date ${THISDATE}"  >> $logfile
        cd $CYCLEDIR 
        if [ $KEEPWORKDIR == "NO" ];   then 
            rm -rf $WORKDIR
        fi
        exit  
    fi

    echo "starting $THISDATE"  

    # get DA settings

    this_config=DA_config$HH
    DA_config=${!this_config}

    if [ $DA_config == "openloop" ]; then do_jedi="NO" ; else do_jedi="YES" ; fi 

    # substringing to get yr, mon, day, hr info
    YYYY=`echo $THISDATE | cut -c1-4`
    MM=`echo $THISDATE | cut -c5-6`
    DD=`echo $THISDATE | cut -c7-8`
    HH=`echo $THISDATE | cut -c9-10`

    # substringing to get yr, mon, day, hr info for previous cycle
    PREVDATE=`${incdate} $THISDATE -6`
    YYYP=`echo $PREVDATE | cut -c1-4`
   
    # compute the restart frequency, run_days and run_hours
    FREQ=$(( 3600 * $FCSTHR ))
    RDD=$(( $FCSTHR / 24 ))
    RHH=$(( $FCSTHR % 24 ))
 
    # substring for next cycle
    NEXTDATE=`${incdate} $THISDATE $FCSTHR`
    nYYYY=`echo $NEXTDATE | cut -c1-4`
    nMM=`echo $NEXTDATE | cut -c5-6`
    nDD=`echo $NEXTDATE | cut -c7-8`
    nHH=`echo $NEXTDATE | cut -c9-10`

    ############################
    # copy restarts to workdir, convert to vector for DA (all members) 

    mem_ens="mem000" 

    MEM_WORKDIR=${WORKDIR}/${mem_ens}
    MEM_MODL_OUTDIR=${OUTDIR}/${mem_ens}
    
    cd $MEM_WORKDIR
    # copy restarts into work directory
    rst_in=${MEM_MODL_OUTDIR}/restarts/vector/ufs_land_restart_back.${YYYY}-${MM}-${DD}_${HH}-00-00.nc
    if [[ ! -e ${rst_in} ]]; then
      rst_in=${LANDDA_INPUTS}/restarts/${atmos_forc}/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc 
    fi
    rst_out=${MEM_WORKDIR}/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc
    cp ${rst_in} ${rst_out}

    if [[ $do_jedi == "YES" ]]; then  
        echo '************************************************'
        echo 'calling tile2vector' 

        export MEM_WORKDIR

        # update vec2tile and tile2vec namelists
        cp  ${CYCLEDIR}/template.vector2tile vector2tile.namelist

        sed -i "s|LANDDA_INPUTS|${LANDDA_INPUTS}|g" vector2tile.namelist
        sed -i -e "s/XXYYYY/${YYYY}/g" vector2tile.namelist
        sed -i -e "s/XXMM/${MM}/g" vector2tile.namelist
        sed -i -e "s/XXDD/${DD}/g" vector2tile.namelist
        sed -i -e "s/XXHH/${HH}/g" vector2tile.namelist
        sed -i -e "s/XXHH/${HH}/g" vector2tile.namelist
        sed -i -e "s/MODEL_FORCING/${atmos_forc}/g" vector2tile.namelist
        sed -i -e "s/XXRES/${RES}/g" vector2tile.namelist
        sed -i -e "s/XXTSTUB/${TSTUB}/g" vector2tile.namelist
        sed -i -e "s#XXTPATH#${TPATH}#g" vector2tile.namelist

        # submit vec2tile 
        echo '************************************************'
        echo 'calling vector2tile' 
        $vec2tileexec vector2tile.namelist
        if [[ $? != 0 ]]; then
            echo "vec2tile failed"
            exit 
        fi
    fi # vector2tile for DA

    ############################
    # do DA update

    if [[ $do_jedi == "YES" ]]; then  

        # submit snow DA 
        echo '************************************************'
        echo 'calling snow DA'

        cd $WORKDIR

        export THISDATE
        $DAscript ${CYCLEDIR}/$DA_config
        if [[ $? != 0 ]]; then
            echo "land DA script failed"
            exit
        fi   
    fi 

    ############################
    #  convert back to vector, run model (all members) convert back to vector, run model (all members)

    mem_ens="mem000" 

    MEM_WORKDIR=${WORKDIR}/${mem_ens}
    MEM_MODL_OUTDIR=${OUTDIR}/${mem_ens}

    cd $MEM_WORKDIR

    if [[ $do_jedi == "YES" ]]; then  
        echo '************************************************'
        echo 'calling tile2vector' 

        cp  ${CYCLEDIR}/template.tile2vector tile2vector.namelist

        sed -i "s|LANDDA_INPUTS|${LANDDA_INPUTS}|g" tile2vector.namelist
        sed -i -e "s/XXYYYY/${YYYY}/g" tile2vector.namelist
        sed -i -e "s/XXMM/${MM}/g" tile2vector.namelist
        sed -i -e "s/XXDD/${DD}/g" tile2vector.namelist
        sed -i -e "s/XXHH/${HH}/g" tile2vector.namelist
        sed -i -e "s/MODEL_FORCING/${atmos_forc}/g" vector2tile.namelist
        sed -i -e "s/XXRES/${RES}/g" tile2vector.namelist
        sed -i -e "s/XXTSTUB/${TSTUB}/g" tile2vector.namelist
        sed -i -e "s#XXTPATH#${TPATH}#g" tile2vector.namelist

        $vec2tileexec tile2vector.namelist
        if [[ $? != 0 ]]; then
            echo "tile2vector failed"
            exit 
        fi

        # save analysis restart
        cp ${MEM_WORKDIR}/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc ${MEM_MODL_OUTDIR}/restarts/vector/ufs_land_restart_anal.${YYYY}-${MM}-${DD}_${HH}-00-00.nc
    fi

    ############################
    # run the forecast model
    set -x 
    # update model namelist 
    cp  ${CYCLEDIR}/template.ufs-noahMP.namelist.${atmos_forc}  ufs-land.namelist

    sed -i "s|LANDDA_INPUTS|${LANDDA_INPUTS}|g" ufs-land.namelist 
    sed -i -e "s/XXYYYY/${YYYY}/g" ufs-land.namelist
    sed -i -e "s/XXMM/${MM}/g" ufs-land.namelist
    sed -i -e "s/XXDD/${DD}/g" ufs-land.namelist
    sed -i -e "s/XXHH/${HH}/g" ufs-land.namelist
    sed -i -e "s/XXFREQ/${FREQ}/g" ufs-land.namelist
    sed -i -e "s/XXRDD/${RDD}/g" ufs-land.namelist
    sed -i -e "s/XXRHH/${RHH}/g" ufs-land.namelist

    # submit model
    echo '************************************************'
    echo "calling model"
    echo $MEM_WORKDIR
    ${MPIEXEC} -n 1 $LSMexec 
    # no error codes on exit from model, check for restart below instead

    ############################
    # check model ouput (all members)

    mem_ens="mem000" 

    MEM_WORKDIR=${WORKDIR}/${mem_ens}
    MEM_MODL_OUTDIR=${OUTDIR}/${mem_ens}

    if [[ -e ${MEM_WORKDIR}/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc ]]; then 
       cp ${MEM_WORKDIR}/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc ${MEM_MODL_OUTDIR}/restarts/vector/ufs_land_restart_back.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc
    else 
       echo "Something is wrong, probably the model, exiting" 
       exit
    fi

#   echo "Finished job number, ${date_count},for  date: ${THISDATE}" >> $logfile

    THISDATE=$NEXTDATE
    date_count=$((date_count+1))

done #  date_count -lt cycles_per_job


############################
# resubmit script 

if [ $THISDATE -lt $ENDDATE ]; then
    echo "STARTDATE=${THISDATE}" > ${analdate}
    echo "ENDDATE=${ENDDATE}" >> ${analdate}
    cd ${CYCLEDIR}
    sbatch ${CYCLEDIR}/submit_cycle.sh
fi

