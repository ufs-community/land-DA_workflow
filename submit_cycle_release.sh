#!/bin/bash -le 
#SBATCH --job-name=offline_noahmp
#SBATCH --account=da-cpu
#SBATCH --qos=batch
#SBATCH --nodes=1
#SBATCH --tasks-per-node=6
#SBATCH --cpus-per-task=1
#SBATCH -t 00:04:00
#SBATCH -o log_noahmp.%j.log
#SBATCH -e err_noahmp.%j.err

############################
# to do: 
# -update ICS directory to include forcing / res info.
# -decide how to manage soil moisture DA. Separate DA script to snow? 

############################

# load config file   
#NOTES--If running with a container, need to get executable scripts set up for all in land-offline_workflow/build/bin, python and fv3-bundle/build/bin/fv3jedi_letkf.x
set -x
ulimit -s unlimited

#Get the directory structure figured out here
dirup=`dirname $PWD`
#Currently, this is the parent directory of land-release. We should probably change this to just be whatever 
#the user wants to call the current "land-release" directory
export LANDDAROOT=${LANDDAROOT:-`dirname $dirup`}
#This is where the land release executables reside. This will be different for singularity
export BUILDDIR=${BUILDDIR:-${LANDDAROOT}/land-release/land-offline_workflow/build}
export PATH=$PATH:./

#TODO Fix this and make it more robust
#Set the environment variable "USE_SINGULARITY" to yes in order to run using a container
if [[ ${USE_SINGULARITY} =~ yes ]]; then
  EPICHOME=/opt
  #use the python that is built into the container. It has all the pythonpaths set and can run the ioda converters
  export PYTHON=$PWD/singularity/bin/python
  #JEDI is installed under /opt in the container
  export JEDI_INSTALL=/opt
  #Scripts that launch containerized versions of the executables are in $PWD/singularity/bin They should be called
  #from the host system to be run (e.g. mpiexec -n 6 $BUILDDIR/bin/fv3jedi_letkf.x )
  export BUILDDIR=$PWD/singularity
  export JEDI_EXECDIR=${LANDDAROOT}/land-release/land-offline_workflow/singularity/bin
  #we need to have intelmpi loaded on the host system to run the workflow. Try to load it here.
  #TODO--figure out a way to make sure we have intelmpi loaded or don't let the workflow start
  module try-load impi
  module try-load intel-oneapi-mpi
  module try-load intelmpi
  module try-load singularity
  export SINGULARITYBIN=`which singularity`
  sed -i 's/singularity exec/${SINGULARITYBIN} exec/g' run_container_executable.sh
elif [[ ${SLURM_SUBMIT_HOST} =~ hfe ]]; then
  # Hera
  EPICHOME=/scratch1/NCEPDEV/nems/role.epic
  export JEDI_INSTALL=/scratch1/NCEPDEV/nems/role.epic/contrib
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${BUILDDIR}/lib
elif [[ ${SLURM_SUBMIT_HOST} =~ Orion ]]; then
  export JEDI_INSTALL=/work/noaa/epic-ps/role-epic-ps/contrib
  EPICHOME=/work/noaa/epic-ps/role-epic-ps
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${BUILDDIR}/lib
fi


module use ${EPICHOME}/miniconda3/modulefiles
module use ${EPICHOME}/spack-stack/envs/landda-release-1.0-intel/install/modulefiles/Core
module try-load stack-intel stack-intel-oneapi-mpi netcdf-c netcdf-fortran cmake ecbuild stack-python
locpython=`which python3 | head -n 1`
export PYTHON=${PYTHON:-${locpython}}
export MPIEXEC=`which mpiexec`
#TODO -- make this more portable--not every install will use python3.9
export PYTHONPATH=${JEDI_INSTALL}/ioda-bundle/build/lib/pyiodaconv:${JEDI_INSTALL}/ioda-bundle/build/lib/python3.9/pyioda

if [[ $# -gt 0 ]]; then 
    config_file=$1
else
    config_file=settings
fi

echo "reading cycle settings from $config_file"

source $config_file

# load modules 

#source cycle_mods_bash

export CYCLEDIR=$(pwd) 

# set executables
vec2tileexec=${BUILDDIR}/bin/vector2tile_converter.exe
LSMexec=${BUILDDIR}/bin/ufsLandDriver.exe 
DADIR=${CYCLEDIR}/DA_update/
DAscript=${DADIR}/do_landDA_release.sh

analdate=${CYCLEDIR}/analdates_sample.sh
incdate=${CYCLEDIR}/incdate.sh

KEEPWORKDIR="YES"

# create clean workdir
if [[ -e ${WORKDIR} ]]; then 
   rm -rf ${WORKDIR} 
fi

mkdir ${WORKDIR}

############################
# create output directories if they do not already exist.

if [[ ! -e ${OUTDIR}/modl ]]; then
    mkdir -p ${OUTDIR}/modl
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

    # if restart not in experiment out directory, copy the restarts from the ICSDIR
    if [[ ! -e ${target_restart} ]]; then 
        echo $source_restart
        # if ensemble of restarts exists in ICSDIR, use these. Otherwise, use single restart.
        if [[ -e ${source_restart} ]]; then
           cp ${source_restart} ${target_restart}
        else  # use non-ensemble restart
           echo 'using single restart for every ensemble member' 
           cp ${ICSDIR}/output/modl/restarts/vector/ufs_land_restart.${sYYYY}-${sMM}-${sDD}_${sHH}-00-00.nc ${target_restart}
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

    # compute the restart frequency, run_days and run_hours
    FREQ=$(( 3600 * $FCSTHR )) 
    RDD=$(( $FCSTHR / 24 )) 
    RHH=$(( $FCSTHR % 24 )) 

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

    #if [ $HH == 00 ]; then DA_config=$DA_config00 ; fi  
    #if [ $HH == 06 ]; then DA_config=$DA_config06 ; fi  
    #if [ $HH == 12 ]; then DA_config=$DA_config12 ; fi  
    #if [ $HH == 18 ]; then DA_config=$DA_config18 ; fi  

    this_config=DA_config$HH
    DA_config=${!this_config}
    if [ $DA_config == "openloop" ]; then do_jedi="NO" ; else do_jedi="YES" ; fi 
    echo "entering JEDI" $do_jedi

    if [ $do_jedi == "YES" ]; then  # do DA

        cd ${WORKDIR}

        # CSDtodo - do for every ensemble member
        # update vec2tile and tile2vec namelists
        cp  ${CYCLEDIR}/template.vector2tile.release vector2tile.namelist

        sed -i "s|LANDDAROOT|${LANDDAROOT}|g" vector2tile.namelist
        sed -i -e "s/XXYYYY/${YYYY}/g" vector2tile.namelist
        sed -i -e "s/XXMM/${MM}/g" vector2tile.namelist
        sed -i -e "s/XXDD/${DD}/g" vector2tile.namelist
        sed -i -e "s/XXHH/${HH}/g" vector2tile.namelist
        sed -i -e "s/XXHH/${HH}/g" vector2tile.namelist
        sed -i -e "s/XXRES/${RES}/g" vector2tile.namelist
        sed -i -e "s/XXTSTUB/${TSTUB}/g" vector2tile.namelist
        sed -i -e "s#XXTPATH#${TPATH}#g" vector2tile.namelist

        cp  ${CYCLEDIR}/template.tile2vector.release tile2vector.namelist

        sed -i "s|LANDDAROOT|${LANDDAROOT}|g" tile2vector.namelist
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
        MEM_OUTDIR=${OUTDIR}/modl/${mem_ens}/ # for model only

        cd $MEM_WORKDIR

        # update model namelist 
     
        if [ $ensemble_size == 1 ]; then
            cp  ${CYCLEDIR}/template.ufs-noahMP.namelist.release.${atmos_forc}  ufs-land.namelist
        else
            #cp ${CYCLEDIR}/template.ens.ufs-noahMP.namelist.${atmos_forc} ufs-land.namelist
            echo 'CSD - temporarily using non-ensemble namelist' 
            cp  ${CYCLEDIR}/template.ufs-noahMP.namelist.release.${atmos_forc}  ufs-land.namelist
        fi

        sed -i "s|LANDDAROOT|${LANDDAROOT}|g" ufs-land.namelist
        sed -i -e "s/XXYYYY/${YYYY}/g" ufs-land.namelist
        sed -i -e "s/XXMM/${MM}/g" ufs-land.namelist
        sed -i -e "s/XXDD/${DD}/g" ufs-land.namelist
        sed -i -e "s/XXHH/${HH}/g" ufs-land.namelist
        sed -i -e "s/XXFREQ/${FREQ}/g" ufs-land.namelist
        sed -i -e "s/XXRDD/${RDD}/g" ufs-land.namelist
        sed -i -e "s/XXRHH/${RHH}/g" ufs-land.namelist
        NN="`printf %02i $n_ens`" # ensemble number 
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
           cp ${MEM_WORKDIR}/restarts/vector/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc ${MEM_OUTDIR}/restarts/vector/ufs_land_restart_back.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.nc
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

