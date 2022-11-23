#!/bin/bash 

############################
# load config file 

if [[ $# -gt 0 ]]; then 
    config_file=$1
else
    config_file=settings
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

source cycle_mods_bash
export CYCLEDIR=$(pwd) 

############################
# set executables

export vec2tileexec=${CYCLEDIR}/vector2tile/vector2tile_converter.exe
export LSMexec=${CYCLEDIR}/ufs-land-driver/run/ufsLand.exe 
export DADIR=${CYCLEDIR}/DA_update/
export DAscript=${DADIR}/do_landDA.sh

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

#workdir
if [[ -e ${WORKDIR} ]]; then 
    rm -rf ${WORKDIR}
fi
mkdir ${WORKDIR}

#outdir for model
if [[ ! -e ${OUTDIR} ]]; then
    mkdir -p  ${OUTDIR}
fi 

###############################
# create ensemble dirs and copy in ICS if needed

n_ens=1
while [ $n_ens -le $ensemble_size ]; do
    echo 'in ensemble loop, '$n_ens

    if [ $ensemble_size == 1 ]; then 
        mem_ens="mem000" 
    else 
        mem_ens="mem`printf %03i $n_ens`"
    fi 

    # ensemble workdir
    MEM_WORKDIR=${WORKDIR}/${mem_ens}
    if [[ ! -e $MEM_WORKDIR ]]; then
      mkdir $MEM_WORKDIR
    fi

    # ensemble outdir (model only)
    MEM_MODL_OUTDIR=${OUTDIR}/${mem_ens}
    if [[ ! -e $MEM_MODL_OUTDIR ]]; then  #ensemble outdir
        mkdir -p $MEM_MODL_OUTDIR
    fi 
    
    # outdir subdirs
    if [[ ! -e ${MEM_MODL_OUTDIR}/restarts/ ]]; then  # subdirectories
        mkdir -p ${MEM_MODL_OUTDIR}/restarts/vector/ 
        mkdir ${MEM_MODL_OUTDIR}/restarts/tile/
        mkdir -p ${MEM_MODL_OUTDIR}/noahmp/
    fi
    ln -sf ${MEM_MODL_OUTDIR}/noahmp ${MEM_WORKDIR}/noahmp_output 

    # copy ICS into restarts, if needed 
    rst_in=${ICSDIR}/${mem_ens}/restarts/vector/ufs_land_restart.${sYYYY}-${sMM}-${sDD}_${sHH}-00-00.nc
    rst_in_single=${ICSDIR}/mem000/restarts/vector/ufs_land_restart.${sYYYY}-${sMM}-${sDD}_${sHH}-00-00.nc
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

# create dates file 
touch analdates.sh 
cat << EOF > analdates.sh
STARTDATE=$STARTDATE
ENDDATE=$ENDDATE
EOF

# submit script 
sbatch submit_cycle.sh

