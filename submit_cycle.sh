#!/bin/bash  
#SBATCH --job-name=ufs_land_da
#SBATCH --account=da-cpu
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
    MP=`echo $PREVDATE | cut -c5-6`
    DP=`echo $PREVDATE | cut -c7-8`
    HP=`echo $PREVDATE | cut -c9-10`
 
    # substring for next cycle
    NEXTDATE=`${incdate} $THISDATE $FCSTHR`
    nYYYY=`echo $NEXTDATE | cut -c1-4`
    nMM=`echo $NEXTDATE | cut -c5-6`
    nDD=`echo $NEXTDATE | cut -c7-8`
    nHH=`echo $NEXTDATE | cut -c9-10`

    ############################
    # copy restarts to workdir, convert to UFS tile for DA (all members) 

    mem_ens="mem000" 

    MEM_WORKDIR=${WORKDIR}/${mem_ens}
    MEM_MODL_OUTDIR=${OUTDIR}/${mem_ens}
    
    cd $MEM_WORKDIR

    if [[ $do_jedi == "YES" && $atmos_forc == "era5" ]]; then
        
        # copy restarts into work directory
    	rst_in=${MEM_MODL_OUTDIR}/restarts/vector/ufs_land_restart_back.${YYYY}-${MM}-${DD}_${HH}-00-00.nc
    	if [[ ! -e ${rst_in} ]]; then
      	rst_in=${LANDDA_INPUTS}/restarts/${atmos_forc}/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc
    	fi
    	rst_out=${MEM_WORKDIR}/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc
    	cp ${rst_in} ${rst_out}

        echo '************************************************'
        echo 'calling vector2tile' 

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

        if [[ $BASELINE =~ 'hera.internal' ]]; then
           source ${CYCLEDIR}/land_mods
        fi
        $vec2tileexec vector2tile.namelist
        if [[ $? != 0 ]]; then
            echo "vec2tile failed"
            exit
        fi
    fi # vector2tile for DA

    if [[ $do_jedi == "YES" && $atmos_forc == "gswp3" ]]; then

    	echo '************************************************'
   	echo 'calling tile2tile'    
 
    	export MEM_WORKDIR
       
       # copy restarts into work directory

    	for tile in 1 2 3 4 5 6
    	do
    	rst_in=${MEM_MODL_OUTDIR}/restarts/tile/ufs_land_restart_back.${YYYY}-${MM}-${DD}_${HH}-00-00.nc
    	if [[ ! -e ${rst_in} ]]; then  
      	rst_in=${LANDDA_INPUTS}/restarts/${atmos_forc}/ufs.cpld.lnd.out.${YYYY}-${MM}-${DD}-00000.tile${tile}.nc
    	fi
    	rst_out=${MEM_WORKDIR}/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${tile}.nc
    	cp ${rst_in} ${rst_out}
    	done

       # update tile2tile namelist
        cp  ${CYCLEDIR}/template.ufs2jedi ufs2jedi.namelist

        sed -i "s|LANDDA_INPUTS|${LANDDA_INPUTS}|g" ufs2jedi.namelist
        sed -i -e "s/XXYYYY/${YYYY}/g" ufs2jedi.namelist
        sed -i -e "s/XXMM/${MM}/g" ufs2jedi.namelist
        sed -i -e "s/XXDD/${DD}/g" ufs2jedi.namelist
        sed -i -e "s/XXHH/${HH}/g" ufs2jedi.namelist
        sed -i -e "s/XXHH/${HH}/g" ufs2jedi.namelist
        sed -i -e "s/MODEL_FORCING/${atmos_forc}/g" ufs2jedi.namelist
        sed -i -e "s/XXRES/${RES}/g" ufs2jedi.namelist
        sed -i -e "s/XXTSTUB/${TSTUB}/g" ufs2jedi.namelist
        sed -i -e "s#XXTPATH#${TPATH}#g" ufs2jedi.namelist

       # submit tile2tile 
       
        if [[ $BASELINE =~ 'hera.internal' ]]; then
           source ${CYCLEDIR}/land_mods
        fi 
        $tile2tileexec ufs2jedi.namelist
        if [[ $? != 0 ]]; then
            echo "tile2tile failed"
            exit 
        fi
    fi # tile2tile for DA

    ############################
    # do DA update

    if [[ $do_jedi == "YES" ]]; then  

        # submit snow DA 
        echo '************************************************'
        echo 'calling snow DA'

        cd $WORKDIR

        export THISDATE
        export EXECdir="${CYCLEDIR}/exec"
        $DAscript ${CYCLEDIR}/$DA_config
        if [[ $? != 0 ]]; then
            echo "land DA script failed"
            exit
        fi   
    fi 
 
    ############################
    #  convert back to vector/tile

    mem_ens="mem000" 

    MEM_WORKDIR=${WORKDIR}/${mem_ens}
    MEM_MODL_OUTDIR=${OUTDIR}/${mem_ens}

    cd $MEM_WORKDIR

    #  convert back to vector, run model (all members) convert back to vector, run model (all members)
    if [[ $do_jedi == "YES" && $atmos_forc == "era5" ]]; then
        echo '************************************************'
        echo 'calling tile2vector' 

        if [[ $BASELINE =~ 'hera.internal' ]]; then
           source ${CYCLEDIR}/land_mods
        fi

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

    #  convert back to UFS tile, run model (all members)
    if [[ $do_jedi == "YES" && $atmos_forc == "gswp3" ]]; then  
        echo '************************************************'
        echo 'calling tile2tile' 
   
        if [[ $BASELINE =~ 'hera.internal' ]]; then
           source ${CYCLEDIR}/land_mods
        fi 
        
        cp  ${CYCLEDIR}/template.jedi2ufs jedi2ufs.namelist
         
        sed -i "s|LANDDA_INPUTS|${LANDDA_INPUTS}|g" jedi2ufs.namelist
        sed -i -e "s/XXYYYY/${YYYY}/g" jedi2ufs.namelist
        sed -i -e "s/XXMM/${MM}/g" jedi2ufs.namelist
        sed -i -e "s/XXDD/${DD}/g" jedi2ufs.namelist
        sed -i -e "s/XXHH/${HH}/g" jedi2ufs.namelist
        sed -i -e "s/MODEL_FORCING/${atmos_forc}/g" jedi2ufs.namelist
        sed -i -e "s/XXRES/${RES}/g" jedi2ufs.namelist
        sed -i -e "s/XXTSTUB/${TSTUB}/g" jedi2ufs.namelist
        sed -i -e "s#XXTPATH#${TPATH}#g" jedi2ufs.namelist

        $tile2tileexec jedi2ufs.namelist
        if [[ $? != 0 ]]; then
            echo "tile2tile failed"
            exit 
        fi

        # save analysis restart
        for tile in 1 2 3 4 5 6
        do
            cp ${MEM_WORKDIR}/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${tile}.nc ${MEM_MODL_OUTDIR}/restarts/tile/ufs_land_restart_anal.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${tile}.nc    
            cp ${MEM_WORKDIR}/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${tile}.nc ${MEM_MODL_OUTDIR}/restarts/tile/ufs.cpld.lnd.out.${YYYY}-${MM}-${DD}-00000.tile${tile}.nc
        done  
    fi

    ############################
    # run the forecast model

    if [[ $do_jedi == "YES" && $atmos_forc == "era5" ]]; then 
        echo '************************************************'
        echo 'running the forecast model'

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
    	echo $MEM_WORKDIR

    	nt=$SLURM_NTASKS
    	if [[ $BASELINE =~ 'hera.internal' ]]; then
            source ${CYCLEDIR}/land_mods
    	fi

    	if [[ $BASELINE =~ 'hera.internal' ]]; then
            srun '--export=ALL' --label -K -n $nt $LSMexec
    	else
            ${MPIEXEC} -n 1 $LSMexec
    	fi
    fi 
    # no error codes on exit from model, check for restart below instead

    if [[ $do_jedi == "YES" && $atmos_forc == "gswp3" ]]; then
	set -e     
 
   	echo '************************************************'
    	echo 'running the forecast model' 
    
    	TEST_NAME=datm_cdeps_lnd_gswp3
    	TEST_NAME_RST=datm_cdeps_lnd_gswp3_rst
    	PATHRT=${CYCLEDIR}/ufs-weather-model/tests
    	RT_COMPILER=${RT_COMPILER:-intel}
    	ATOL="1e-7"

        cp $CYCLEDIR/$TEST_NAME_RST ${PATHRT}/tests/$TEST_NAME_RST 
       	source ${PATHRT}/detect_machine.sh
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
    	cp ${CYCLEDIR}/exec/ufs_model .
        cp ${CYCLEDIR}/fv3_run ./fv3_run
 
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
    	export MPIRUN=${MPIRUN:-`which mpiexec`}
    	${MPIRUN} -n ${TASKS} ./ufs_model
    fi

    # no error codes on exit from model, check for restart below instead

    ############################
    # check model ouput (all members)

    mem_ens="mem000"

    MEM_WORKDIR=${WORKDIR}/${mem_ens}
    MEM_MODL_OUTDIR=${OUTDIR}/${mem_ens}
  
    if [[ $atmos_forc == "era5" ]]; then
  #  if [[ -e ${MEM_WORKDIR}/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc ]]; then
       cp ${MEM_WORKDIR}/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc ${MEM_MODL_OUTDIR}/restarts/vector/ufs_land_restart_back.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc
    else
       for tile in 1 2 3 4 5 6
        do
           cp ${MEM_WORKDIR}/noahmp_output/${TEST_NAME_RST}/ufs.cpld.lnd.out.${nYYYY}-${nMM}-${nDD}-00000.tile${tile}.nc ${MEM_MODL_OUTDIR}/restarts/tile/ufs_land_restart_back.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.tile${tile}.nc
        done
    fi
    
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

