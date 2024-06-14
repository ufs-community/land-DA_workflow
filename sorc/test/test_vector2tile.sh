#!/bin/bash
set -e
################################################
# pass arguments
project_binary_dir=$1
project_source_dir=$2
DIRECTION=$3
prefix=$4 #bkg or ana

# Export runtime env. variables
source ${project_source_dir}/test/runtime_vars.sh ${project_binary_dir} ${project_source_dir}

# set baseline dir
export TEST_BASEDIR=${TEST_BASEDIR:-"${EPICHOME}/test_base/mem000/restarts/vector"}

# set executables
TEST_EXEC="vector2tile_converter.exe"
NPROC=1

# move to work directory
cd $WORKDIR

# Clean test files created during a previous test
# only clean vector folder for now
[[ -e ${WORKDIR}/${prefix}/restarts/vector ]] && rm -rf ${WORKDIR}/${prefix}/restarts/vector
[[ ${DIRECTION} = "vector2tile" ]] && rm -rf ${WORKDIR}/${prefix}/restarts/tile
[[ -e ./vector2tile.namelist ]] && rm vector2tile.namelist

# copy vector restarts
mkdir -p $WORKDIR/${prefix}/restarts/vector
source_restart=${FIXlandda}/restarts/${atmos_forc}/ufs_land_restart.${YY}-${MM}-${DD}_${HH}-00-00.nc
target_restart=$WORKDIR/${prefix}/restarts/vector/ufs_land_restart.${YY}-${MM}-${DD}_${HH}-00-00.nc
cp $source_restart $target_restart

# select case
case $DIRECTION in

  vector2tile)
    echo "============================= direction: ${DIRECTION}"
    [[ ! -e ${WORKDIR}/${prefix}/restarts/tile ]] && mkdir -p ${WORKDIR}/${prefix}/restarts/tile
    # set variables for namelist
    VECTOR_PATH=./PREFIX/restarts/vector/
    TILE_PATH=junk
    OUTPUT_PATH=./PREFIX/restarts/tile/
    ;;

  tile2vector)
    echo "============================= direction: ${DIRECTION}"
    # Assume tile files are already created by apply_incr test
    #  in .${prefix}/restarts/tile 
    for tile in 1 2 3 4 5 6
    do
        if [[ ! -e $WORKDIR/${prefix}/restarts/tile/${FILEDATE}.sfc_data.tile${tile}.nc ]]; then
        echo "$WORKDIR/${prefix}/restarts/tile/${FILEDATE}.sfc_data.tile${tile}.nc missing"
        exit 1
        fi
    done
    # set variables for namelist
    VECTOR_PATH=junk
    TILE_PATH=./PREFIX/restarts/tile/
    OUTPUT_PATH=./PREFIX/restarts/vector/
    # if prefix = ana, turn on baseline check
    [[ ${prefix} == "ana" ]] && BASELINE_CHECK="true"
    ;;

  *)
    echo "============================= direction unknown stop now!"
    exit 1
    ;;
esac

# update namelist
cp  ${project_source_dir}/test/testinput/template.vector2tile vector2tile.namelist
sed -i "s|DIRECTION|${DIRECTION}|g" vector2tile.namelist
sed -i "s|FIXlandda|${FIXlandda}|g" vector2tile.namelist
sed -i "s|VECTOR_PATH|${VECTOR_PATH}|g" vector2tile.namelist
sed -i "s|TILE_PATH|${TILE_PATH}|g" vector2tile.namelist
sed -i "s|OUTPUT_PATH|${OUTPUT_PATH}|g" vector2tile.namelist
sed -i "s|PREFIX|${prefix}|g" vector2tile.namelist
sed -i -e "s/XXYYYY/${YY}/g" vector2tile.namelist
sed -i -e "s/XXMM/${MM}/g" vector2tile.namelist
sed -i -e "s/XXDD/${DD}/g" vector2tile.namelist
sed -i -e "s/XXHH/${HH}/g" vector2tile.namelist
sed -i -e "s/XXRES/${RES}/g" vector2tile.namelist
sed -i -e "s#XXTPATH#${TPATH}#g" vector2tile.namelist
sed -i -e "s/XXTSTUB/${TSTUB}/g" vector2tile.namelist


# run test
echo "============================= calling ${TEST_EXEC}"
${MPIRUN} -n ${NPROC} ${EXECDIR}/${TEST_EXEC} vector2tile.namelist

# check anal rst with baseline
if [[ ${BASELINE_CHECK} == "true" ]]; then
  echo "============================= baseline check with tol= ${TOL}"
  ${project_source_dir}/test/compare.py ./${prefix}/restarts/vector/ufs_land_restart.${YY}-${MM}-${DD}_${HH}-00-00.nc ${TEST_BASEDIR}/ufs_land_restart_anal.${YY}-${MM}-${DD}_${HH}-00-00.nc ${TOL}
  if [[ $? != 0 ]]; then
      echo "baseline check fail!"
      exit 20
  fi
fi
