#!/bin/bash
set -e
################################################
# pass arguments
project_source_dir=$1

# first retrieve test data for landda system
cd ${project_source_dir}/../../
[[ ! -f landda-test-inps.tar.gz ]] && wget https://noaa-ufs-land-da-pds.s3.amazonaws.com/landda_inputs.tar.gz
[[ ! -d inputs ]] && tar xvfz landda_inputs.tar.gz
cd ${project_source_dir}

# Then retrieve data for ufs-datm-lnd model test (RT: datm_cdeps_lnd_gswp3)

# First load modules
PATHRT=${project_source_dir}/ufs_model.fd/tests
RT_COMPILER=${RT_COMPILER:-intel}

# install aws
# users have to load modules before running the script
pip3 install awscli --upgrade --user
export PATH=${HOME}/.local/bin:${PATH}

# set envs
DATA_ROOT=${project_source_dir}/../fix
INPUTDATA_ROOT=${DATA_ROOT}/input/UFS_WM

[[ ! -d ${INPUTDATA_ROOT} ]] && mkdir -p ${INPUTDATA_ROOT}
RTPWD=${DATA_ROOT}/test_base
AWS_URL=s3://noaa-ufs-regtests-pds

# baseline data
DES_DIR=${RTPWD}/datm_cdeps_lnd_gswp3_intel
[[ ! -d ${DES_DIR} ]] && mkdir -p ${DES_DIR}
echo ${DES_DIR}
cd $DES_DIR
aws s3 sync --no-sign-request ${AWS_URL}/test_base/datm_cdeps_lnd_gswp3_intel .
cd ${project_source_dir}

# DATM data
DES_DIR=${INPUTDATA_ROOT}/DATM_GSWP3_input_data
[[ ! -d ${DES_DIR} ]] && mkdir -p ${DES_DIR}
echo ${DES_DIR}
cd $DES_DIR
aws s3 sync --no-sign-request ${SRC_DIR}/DATM_GSWP3_input_data .
cd ${project_source_dir}

# fixed data
DES_DIR=${INPUTDATA_ROOT}/FV3_fix_tiled/C96
[[ ! -d ${DES_DIR} ]] && mkdir -p ${DES_DIR}
echo ${DES_DIR}
cd $DES_DIR
aws s3 sync --no-sign-request ${AWS_URL}/FV3_fix_tiled/C96 .

# input data
DES_DIR=${INPUTDATA_ROOT}/FV3_input_data/INPUT
[[ ! -d ${DES_DIR} ]] && mkdir -p ${DES_DIR}
echo ${DES_DIR}
cd $DES_DIR
aws s3 cp --no-sign-request ${SRC_DIR}/FV3_input_data/INPUT/C96_grid.tile1.nc .
aws s3 cp --no-sign-request ${SRC_DIR}/FV3_input_data/INPUT/C96_grid.tile2.nc .
aws s3 cp --no-sign-request ${SRC_DIR}/FV3_input_data/INPUT/C96_grid.tile3.nc .
aws s3 cp --no-sign-request ${SRC_DIR}/FV3_input_data/INPUT/C96_grid.tile4.nc .
aws s3 cp --no-sign-request ${SRC_DIR}/FV3_input_data/INPUT/C96_grid.tile5.nc .
aws s3 cp --no-sign-request ${SRC_DIR}/FV3_input_data/INPUT/C96_grid.tile6.nc .
aws s3 cp --no-sign-request ${SRC_DIR}/FV3_input_data/INPUT/grid_spec.nc .
cd ${project_source_dir}

# NOAHMP ICs
DES_DIR=${INPUTDATA_ROOT}/NOAHMP_IC
[[ ! -d ${DES_DIR} ]] && mkdir -p ${DES_DIR}
echo ${DES_DIR}
cd $DES_DIR
aws s3 sync --no-sign-request ${SRC_DIR}/NOAHMP_IC .
cd ${project_source_dir}
