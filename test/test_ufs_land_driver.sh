#!/bin/bash
set -e
################################################
# pass arguments
project_binary_dir=$1
project_source_dir=$2

# Export runtime env. variables
source ${project_source_dir}/test/runtime_vars.sh ${project_binary_dir} ${project_source_dir}

# set baseline dir
#TEST_BASEDIR=${TEST_BASEDIR:-"${EPICHOME}/landda/cycle_land/DA_GHCN_test/mem000/restarts/vector"}
TEST_BASEDIR=${TEST_BASEDIR:-"/scratch2/NAGAPE/epic/UFS_Land-DA/test_base/mem000/restarts/vector"}

# compute the restart frequency, run_days and run_hours
FREQ=$(( 3600 * $FCSTHR ))
RDD=$(( $FCSTHR / 24 ))
RHH=$(( $FCSTHR % 24 ))

# set executables
TEST_EXEC="ufsLand.exe"
NPROC=1

# move to work directory
cd $WORKDIR

# clean output folder
[[ -e ufs-land.namelist ]] && rm ufs-land.namelist
for i in ./ufs_land_restart*.nc;
do
  [[ -e $i ]] && rm $i
done
for i in ./ufs_land_output*.nc;
do
  [[ -e $i ]] && rm $i
done

# update model namelist
cp $project_source_dir/template.ufs-noahMP.namelist.${atmos_forc}  ufs-land.namelist
sed -i "s|LANDDA_INPUTS|${LANDDA_INPUTS}|g" ufs-land.namelist
sed -i -e "s/XXYYYY/${YY}/g" ufs-land.namelist
sed -i -e "s/XXMM/${MM}/g" ufs-land.namelist
sed -i -e "s/XXDD/${DD}/g" ufs-land.namelist
sed -i -e "s/XXHH/${HH}/g" ufs-land.namelist
sed -i -e "s/XXFREQ/${FREQ}/g" ufs-land.namelist
sed -i -e "s/XXRDD/${RDD}/g" ufs-land.namelist
sed -i -e "s/XXRHH/${RHH}/g" ufs-land.namelist

# link to resart file
ln -fs ${WORKDIR}/ana/restarts/vector/ufs_land_restart.${YY}-${MM}-${DD}_${HH}-00-00.nc .

# submit model
echo "============================= calling model" 
$MPIRUN -n $NPROC ${EXECDIR}/${TEST_EXEC} 

# check if new restart exits
if [[ -e "./ufs_land_restart.${nYY}-${nMM}-${nDD}_${nHH}-00-00.nc" ]]; then
    echo "run fcst model successed!"
else
    echo "run fcst failed"
    exit 10
fi

# check model rst with baseline
echo "============================= baseline check with tol= ${TOL}"
${project_source_dir}/test/compare.py ./ufs_land_restart.${nYY}-${nMM}-${nDD}_${nHH}-00-00.nc ${TEST_BASEDIR}/ufs_land_restart_back.${nYY}-${nMM}-${nDD}_${nHH}-00-00.nc ${TOL}
if [[ $? != 0 ]]; then
    echo "baseline check fail!"
    exit 20
fi
