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
# to do: 
# -specify resolution in this script (currently fixed at 96) 
# -decide how to manage soil moisture DA. Separate DA script to snow? 
# -add ensemble options

############################
# experiment name 

exp_name=openloop_testing

############################
# model options

export ensemble_size=1 # ensemble_size of 1 = do not run ensemble 
                       # LETKF-OI pseudo ensemble uses 1

atmos_forc='gdas' # options gdas, gswp3

dates_per_job=2 # number of cycles to submit in a single job

############################
# DA options

# select YES or NO
export do_DA=NO   # do full DA update
do_hofx=NO  # use JEDI to calculate hofx, but do not do update 
             # only used if do_DA=NO  
export ASSIM_IMS=NO
export ASSIM_GHCN=YES
export ASSIM_SYNTH=NO

DAtype="letkfoi_snow" # options: "letkfoi_snow" , "letkf_snow"

############################
# set your directories

CYCLEDIR=$(pwd)  # this directory
export WORKDIR=/scratch2/BMC/gsienkf/Clara.Draper/workdir/ # temporary work dir 
export OUTDIR=${CYCLEDIR}/exp_out/${exp_name}/output/      # directory where output will be saved
ICSDIR="./ICS/"                                            # OUTDIR for experiment with initial conditions
                                                           # will use ensemble of restarts if present, otherwise will try 
                                                           # to copy a non-ensemble restart into each ensemble restart
                                
#############################################################################################################################
# shouldn't need to change anything below here

# load modules 

source cycle_mods_bash

# set executables

vec2tileexec=${CYCLEDIR}/vector2tile/vector2tile_converter.exe
LSMexec=${CYCLEDIR}/ufs_land_driver/ufsLand.exe 
DAscript=${CYCLEDIR}/landDA_workflow/do_snowDA.sh 
export DADIR=${CYCLEDIR}/landDA_workflow/

analdate=${CYCLEDIR}/analdates.sh
incdate=${CYCLEDIR}/incdate.sh

# create clean workdir
if [[ -e ${WORKDIR} ]]; then 
   rm -rf ${WORKDIR} 
fi

mkdir ${WORKDIR}

############################
# create the jedi yaml name 

if [[ $do_DA == "YES" || $do_hofx == "YES" ]]; then  # do DA
   do_jedi=YES
   # construct yaml name
   if [ $do_DA == "YES" ]; then
        JEDI_YAML=${DAtype}"_offline_DA"
   elif [ $do_hofx == "YES" ]; then
        JEDI_YAML=${DAtype}"_offline_hofx"
   fi

   if [ $ASSIM_IMS == "YES" ]; then JEDI_YAML=${JEDI_YAML}"_IMS" ; fi
   if [ $ASSIM_GHCN == "YES" ]; then JEDI_YAML=${JEDI_YAML}"_GHCN" ; fi
   if [ $ASSIM_SYNTH == "YES" ]; then JEDI_YAML=${JEDI_YAML}"_SYNTH"; fi

   JEDI_YAML=${JEDI_YAML}"_C96.yaml" # IMS and GHCN

   echo "JEDI YAML is: "$JEDI_YAML

   if [[ ! -e ./landDA_workflow/jedi/fv3-jedi/yaml_files/$JEDI_YAML ]]; then
        echo "YAML does not exist, exiting" 
        exit
   fi
   export JEDI_YAML
else
   do_jedi=NO
fi

############################
# create output directories if they do not already exist.

if [[ ! -e ${OUTDIR} ]]; then
    mkdir -p ${OUTDIR}/DA
    mkdir ${OUTDIR}/DA/IMSproc 
    mkdir ${OUTDIR}/DA/jedi_incr
    mkdir ${OUTDIR}/DA/logs
    mkdir ${OUTDIR}/DA/hofx
    mkdir ${OUTDIR}/modl
    n_ens=1
    while [ $n_ens -le $ensemble_size ]; do

        if [ $ensemble_size == 1 ]; then 
            mem_ens="" 
        else 
            mem_ens="mem`printf %03i $n_ens`"
        fi 

        mkdir -p ${OUTDIR}/modl/${mem_ens}/restarts/vector/ 
        mkdir ${OUTDIR}/modl/${mem_ens}/restarts/tile/
        mkdir -p ${OUTDIR}/modl/${mem_ens}/noahmp/
        n_ens=$((n_ens+1))
    done # n_ens < ensemble_size
fi 

############################
# fetch initial conditions, if not already in place 

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

# copy initial conditions
n_ens=1
while [ $n_ens -le $ensemble_size ]; do

    if [ $ensemble_size == 1 ]; then 
        mem_ens="" 
    else 
        mem_ens="mem`printf %03i $n_ens`"
    fi 

    MEM_OUTDIR=${OUTDIR}/modl/${mem_ens}/
    MEM_ICSDIR=${ICSDIR}/modl/${mem_ens}/

    source_restart=${MEM_ICSDIR}/restarts/vector/ufs_land_restart.${sYYYY}-${sMM}-${sDD}_${sHH}-00-00.nc
    target_restart=${MEM_OUTDIR}/restarts/vector/ufs_land_restart_back.${sYYYY}-${sMM}-${sDD}_${sHH}-00-00.nc

    # if ensemble of restarts exist, use these. Otherwise, use single restart.
    if [[ ! -e ${target_restart} ]]; then 
        if [[ -e ${source_restart} ]]; then
           cp ${source_restart} ${target_restart}
        else  # use non-ensemble restart
           echo 'using single restart for every ensemble member' 
           cp ${ICSDIR}/modl/restarts/vector/ufs_land_restart.${sYYYY}-${sMM}-${sDD}_${sHH}-00-00.nc ${target_restart}
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
        rm -rf $WORKDIR
        exit  
    fi

    echo "starting $THISDATE"  

    # substringing to get yr, mon, day, hr info
    export YYYY=`echo $THISDATE | cut -c1-4`
    export MM=`echo $THISDATE | cut -c5-6`
    export DD=`echo $THISDATE | cut -c7-8`
    export HH=`echo $THISDATE | cut -c9-10`

    ############################
    # create work directory and copy in restarts

    n_ens=1
    while [ $n_ens -le $ensemble_size ]; do

        if [ $ensemble_size == 1 ]; then 
            mem_ens="" 
        else 
            mem_ens="mem`printf %03i $n_ens`"
        fi 
        
        MEM_WORKDIR=${WORKDIR}/${mem_ens}/
        MEM_OUTDIR=${OUTDIR}/modl/${mem_ens}/ # for model only

        # create temporary workdir
        if [[ -d $MEM_WORKDIR ]]; then 
          rm -rf $MEM_WORKDIR
        fi 

        # move to work directory, and copy in templates and restarts
        mkdir -p $MEM_WORKDIR
        cd $MEM_WORKDIR

        ln -s ${MEM_OUTDIR}/noahmp/ ${MEM_WORKDIR}/noahmp_output 

        mkdir ${MEM_WORKDIR}/restarts
        mkdir ${MEM_WORKDIR}/restarts/tile
        mkdir ${MEM_WORKDIR}/restarts/vector

        # copy restarts into work directory
        source_restart=${MEM_OUTDIR}/restarts/vector/ufs_land_restart_back.${YYYY}-${MM}-${DD}_${HH}-00-00.nc 
        target_restart=${MEM_WORKDIR}/restarts/vector/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc
        cp $source_restart $target_restart 

        n_ens=$((n_ens+1))

    done # n_ens < ensemble_size

    ############################
    # call JEDI 

    if [ $do_jedi == "YES" ]; then  # do DA

        cd ${WORKDIR}

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
        cp ${WORKDIR}/restarts/vector/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc ${OUTDIR}/${mem_ens}/vector/ufs_land_restart_anal.${YYYY}-${MM}-${DD}_${HH}-00-00.nc

    fi # DA step

    ############################
    # run the forecast model

    NEXTDATE=`${incdate} $THISDATE 24`
    export nYYYY=`echo $NEXTDATE | cut -c1-4`
    export nMM=`echo $NEXTDATE | cut -c5-6`
    export nDD=`echo $NEXTDATE | cut -c7-8`
    export nHH=`echo $NEXTDATE | cut -c9-10`

    # loop over ensemble members

    n_ens=1
    while [ $n_ens -le $ensemble_size ]; do

        if [ $ensemble_size == 1 ]; then 
            mem_ens="" 
        else 
            mem_ens="mem`printf %03i $n_ens`"
        fi 

        MEM_WORKDIR=${WORKDIR}/${mem_ens}/
        MEM_OUTDIR=${OUTDIR}/modl/${mem_ens}/ # for model only

        cd $MEM_WORKDIR

        # update model namelist 
     
        if [ $ensemble_size == 1 ]; then
            cp  ${CYCLEDIR}/template.ufs-noahMP.namelist.${atmos_forc}  ufs-land.namelist
        else
            #cp ${CYCLEDIR}/template.ens.ufs-noahMP.namelist.${atmos_forc} ufs-land.namelist
            echo 'CSD - temporarily using non-ensemble namelist' 
            cp  ${CYCLEDIR}/template.ufs-noahMP.namelist.${atmos_forc}  ufs-land.namelist
        fi

        sed -i -e "s/XXYYYY/${YYYY}/g" ufs-land.namelist
        sed -i -e "s/XXMM/${MM}/g" ufs-land.namelist
        sed -i -e "s/XXDD/${DD}/g" ufs-land.namelist
        sed -i -e "s/XXHH/${HH}/g" ufs-land.namelist

        # CSD - todo: add ensemble forcing here

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
           cp ${MEM_WORKDIR}/restarts/vector/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc ${MEM_OUTDIR}/restarts/vector/ufs_land_restart_back.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc
        else 
           echo "Something is wrong, probably the model, exiting" 
           exit
        fi

        n_ens=$((n_ens+1))
    done # n_ens < ensemble_size

    echo "Finished job number, ${date_count},for  date: ${THISDATE}" >> $logfile

    #THISDATE=`${incdate} $THISDATE 24`
    THISDATE=$NEXTDATE
    date_count=$((date_count+1))

done #  date_count -lt dates_per_job


############################
# resubmit script 

if [ $THISDATE -lt $ENDDATE ]; then
    echo "export STARTDATE=${THISDATE}" > ${analdate}
    echo "export ENDDATE=${ENDDATE}" >> ${analdate}
    cd ${CYCLEDIR}
    sbatch ${CYCLEDIR}/submit_cycle.sh
fi

