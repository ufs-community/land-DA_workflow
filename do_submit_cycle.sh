#!/bin/bash 

set -x
#Set defaults
export LANDDAROOT=${LANDDAROOT:-`dirname $PWD`}
export LANDDA_INPUTS=${LANDDA_INPUTS:-${LANDDAROOT}/inputs}
export LAND_OFFLINE_WORKFLOW=${LAND_OFFLINE_WORKFLOW:-${LANDDAROOT}/land-offline_workflow}
export CYCLE_LAND=${CYCLE_LAND:-${LANDDAROOT}/cycle_land}
export PYTHON=`which python3`
export BUILDDIR=${BUILDDIR:-${LAND_OFFLINE_WORKFLOW}/build}
export PATH=$PATH:./
export CYCLEDIR=$(pwd) 

#Change some variables if working with a container
if [[ ${USE_SINGULARITY} =~ yes ]]; then
  EPICHOME=/opt
  #use the python that is built into the container. It has all the pythonpaths set and can run the ioda converters
  export PYTHON=$PWD/singularity/bin/python
  #JEDI is installed under /opt in the container
  export JEDI_INSTALL=/opt
  #Scripts that launch containerized versions of the executables are in $PWD/singularity/bin They should be called
  #from the host system to be run (e.g. mpiexec -n 6 $BUILDDIR/bin/fv3jedi_letkf.x )
  export BUILDDIR=$PWD/singularity
  export JEDI_EXECDIR=${LAND_OFFLINE_WORKFLOW}/singularity/bin
  #we need to have intelmpi loaded on the host system to run the workflow. Try to load it here.
  #TODO--figure out a way to make sure we have intelmpi loaded or don't let the workflow start
  module try-load impi
  module try-load intel-oneapi-mpi
  module try-load intelmpi
  module try-load singularity
  export SINGULARITYBIN=`which singularity`
  sed -i 's/singularity exec/${SINGULARITYBIN} exec/g' run_container_executable.sh
fi

############################
# load config file 

if [[ $# -gt 0 ]]; then 
    config_file=$1
else
    config_file=settings_DA_cycle_gdas
fi

if [[ ! -e $config_file ]]; then
    echo 'Config file does not exist. Exiting. '
    echo $config_file 
    exit 
fi

echo "reading cycle settings from $config_file"
source $config_file

export KEEPWORKDIR="YES"

############################
# load modules 
# TODO--Do we want to check to see if modules are loaded? Try to load them based on which host we are on?
# Currently, the user must load modules before running

############################
# set executables

export vec2tileexec=${BUILDDIR}/bin/vector2tile_converter.exe
export LSMexec=${BUILDDIR}/bin/ufsLandDriver.exe
export DADIR=${CYCLEDIR}/DA_update/
export DAscript=${DADIR}/do_landDA.sh
export MPIEXEC=`which mpiexec`

export analdate=${CYCLEDIR}/analdates.sh
export incdate=${CYCLEDIR}/incdate.sh

############################
# read in dates  

export logfile=${CYCLEDIR}/cycle.log
touch $logfile
echo "***************************************" >> $logfile
echo "cycling from $STARTDATE to $ENDDATE" >> $logfile

sYYYY=`echo $STARTDATE | cut -c1-4`
sMM=`echo $STARTDATE | cut -c5-6`
sDD=`echo $STARTDATE | cut -c7-8`
sHH=`echo $STARTDATE | cut -c9-10`

# compute the restart frequency, run_days and run_hours
export FREQ=$(( 3600 * $FCSTHR )) 
export RDD=$(( $FCSTHR / 24 )) 
export RHH=$(( $FCSTHR % 24 )) 

############################
# set up directories

##workdir
#if [[ -e ${WORKDIR} ]]; then 
#    rm -rf ${WORKDIR}
#fi
#mkdir ${WORKDIR}
#
##outdir for model
#if [[ ! -e ${OUTDIR} ]]; then
#    mkdir -p  ${OUTDIR}
#fi 

################################
## create dirs and copy in ICS if needed
#
#mem_ens="mem000"  # single member, us ensemble 0
#
#MEM_WORKDIR=${WORKDIR}/${mem_ens}
#if [[ ! -e $MEM_WORKDIR ]]; then
#  mkdir $MEM_WORKDIR
#fi
#
## ensemble outdir (model only)
#MEM_MODL_OUTDIR=${OUTDIR}/${mem_ens}
#if [[ ! -e $MEM_MODL_OUTDIR ]]; then  #ensemble outdir
#    mkdir -p $MEM_MODL_OUTDIR
#fi 
#
## outdir subdirs
#if [[ ! -e ${MEM_MODL_OUTDIR}/restarts/ ]]; then  # subdirectories
#    mkdir -p ${MEM_MODL_OUTDIR}/restarts/vector/ 
#    mkdir ${MEM_MODL_OUTDIR}/restarts/tile/
#    mkdir -p ${MEM_MODL_OUTDIR}/noahmp/
#fi
#ln -sf ${MEM_MODL_OUTDIR}/noahmp ${MEM_WORKDIR}/noahmp_output 
#
## copy ICS into restarts, if needed 
#rst_in=${ICSDIR}/${mem_ens}/restarts/vector/ufs_land_restart.${sYYYY}-${sMM}-${sDD}_${sHH}-00-00.nc
#rst_out=${MEM_MODL_OUTDIR}/restarts/vector/ufs_land_restart_back.${sYYYY}-${sMM}-${sDD}_${sHH}-00-00.nc
#rst_in_single=${LANDDA_INPUTS}/single/output/modl/restarts/vector/ufs_land_restart.${sYYYY}-${sMM}-${sDD}_${sHH}-00-00.nc
#
## if restart not in experiment out directory, copy the restarts from the ICSDIR
#if [[ ! -e ${rst_out} ]]; then
#   echo "Looking for ICS: ${rst_in}"
#   # if ensemble of restarts exists in ICSDIR, use these. Otherwise, use single restart.
#   if [[ -e ${rst_in} ]]; then
#      echo "ICS found, copying" 
#      cp ${rst_in} ${rst_out}
#   else  # use non-ensemble restart
#      echo "ICS not found. Checking for ensemble started from single member: ${rst_in_single}"
#      if [[ -e ${rst_in_single} ]]; then
#          echo "ICS found, copying" 
#          cp ${rst_in_single} ${rst_out}
#      else
#          echo "ICS not found. Exiting" 
#          exit 10
#      fi
#   fi
#fi

# create dates file 
touch analdates.sh 
cat << EOF > analdates.sh
STARTDATE=$STARTDATE
ENDDATE=$ENDDATE
EOF

# submit script 
sbatch submit_cycle.sh

