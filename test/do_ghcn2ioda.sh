#!/bin/bash
set -e
################################################
# CREATE GHCN ioda obs file
################################################
#
# pass arguments
project_binary_dir=$1
project_source_dir=$2

# Export runtime env. variables
source ${project_source_dir}/test/runtime_vars.sh ${project_binary_dir} ${project_source_dir}

# move to work directory
cd $WORKDIR

# create GHCN ioda file
${project_source_dir}/test/ghcn_snod2ioda.py -i ${project_source_dir}/test/testinput/ghcn_20200228.csv -o ./ghcn_snod_20200228.nc -f ${project_source_dir}/test/testinput/ghcn-stations.txt -d 20200228 -m maskout

# baseline comp
echo "============================= baseline check with atol= ${TOL}"
${project_source_dir}/test/compare.py ./ghcn_snod_20200228.nc ${project_source_dir}/test/testref/ref_ghcn_snod_20200228.nc ${TOL}
if [[ $? != 0 ]]; then
    echo "baseline check fail!"
    exit 20
fi
