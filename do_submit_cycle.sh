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
# ensure necessary envars are set
envars=("exp_name" "STARTDATE" "ENDDATE" "LANDDAROOT" "LANDDA_INPUTS" "CYCLEDIR" \
        "LANDDA_EXPTS" "PYTHON" "BUILDDIR" "atmos_forc" "OBSDIR" "WORKDIR" \
        "OUTDIR" "TEST_BASEDIR" "JEDI_EXECDIR" "JEDI_STATICDIR" "ensemble_size" \
        "FCSTHR" "RES" "TPATH" "TSTUB" "cycles_per_job" "ICSDIR" "DA_config" \
        "DA_config00" "DA_config06" "DA_config12" "DA_config18")

for var in "${envars[@]}"; do
  if [ -z "${!var}" ]; then
    unset_envars+=("$var")
  fi
done

if [ ${#unset_envars[@]} -ne 0 ]; then
  echo "ERROR: the following environmental variables have not been set: ${unset_envars[@]}."
  exit 1
fi

############################
# check that modules are loaded in the environment

${CYCLEDIR}/module_check.sh

if [[ $? -ne 0 ]]; then
  exit 1
fi

############################
# check that a valid account for job submission
# is set in submit_cycle.sh (only on Orion/Hera)

if [[ ${HOSTNAME} == *"Orion"* || ${HOSTNAME} == *"hfe"* ]]; then
  user_accounts=$(echo $(sacctmgr show assoc where user=$USER format=account) | sed 's|.*--- \(.*\)|\1|')
  preset_account=$(grep '#SBATCH --account=' submit_cycle.sh | cut -d= -f2)

  # if the account set in submit_cycle matches any of ${user_accounts}, continue;
  # if not, esuggest a compute account to which the user has access and exit.
  if echo "$user_accounts" | grep -q -w "${preset_account}"; then
    echo "Account for sbatch submission set to ${preset_account}."
  else
    echo "Warning: You don't have access to the ${preset_account} compute account. You might try setting the #SBATCH --account in submit_cycle.sh to one of the following accounts instead before re-submitting: ${user_acceunts}."
    exit 1
  fi
fi

############################
# set executables

if [[ -e ${BUILDDIR}/bin/vector2tile_converter.exe ]]; then #prefer cmake-built executables
  export vec2tileexec=${BUILDDIR}/bin/vector2tile_converter.exe
else 
  export vec2tileexec=${CYCLEDIR}/vector2tile/vector2tile_converter.exe
fi
if [[ -e ${BUILDDIR}/bin/ufsLandDriver.exe ]]; then
  export LSMexec=${BUILDDIR}/bin/ufsLandDriver.exe
else
  export LSMexec=${CYCLEDIR}/ufs-land-driver/driver/ufsLandDriver.exe
fi

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
# create dirs and copy in ICS if needed

mem_ens="mem000"  # single member, us ensemble 0

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

# create dates file 
touch analdates.sh 
cat << EOF > analdates.sh
STARTDATE=$STARTDATE
ENDDATE=$ENDDATE
EOF

# submit script 
sbatch submit_cycle.sh

