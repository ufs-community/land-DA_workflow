#!/bin/bash
set -eux
ln -fs /scratch2/NAGAPE/epic/UFS_Land-DA/inputs /scratch1/NCEPDEV/stmp2/role.epic/jenkins/workspace/ && module use modu\
lefiles && module load landda_hera.intel && ecbuild ../ && make -j4 && ctest
