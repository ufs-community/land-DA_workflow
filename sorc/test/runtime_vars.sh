#!/bin/bash
set -e

# pass arguments
project_binary_dir=$1
project_source_dir=$2

# Prepare runtime environement
# set date
export CYMDH=2019122100
export YY=`echo $CYMDH | cut -c1-4`
export MM=`echo $CYMDH | cut -c5-6`
export DD=`echo $CYMDH | cut -c7-8`
export HH=`echo $CYMDH | cut -c9-10`

export DOY=$(date +%j -d "$YY$MM$DD + 1 day")

export FILEDATE=$YY$MM$DD.${HH}0000

export PYMDH=$(date +%Y%m%d%H -d "$YY$MM$DD $HH - 24 hours")
export YP=`echo $PYMDH | cut -c1-4`
export MP=`echo $PYMDH | cut -c5-6`
export DP=`echo $PYMDH | cut -c7-8`
export HP=`echo $PYMDH | cut -c9-10`

export FCSTHR=24
export NYMDH=$(date +%Y%m%d%H -d "$YY$MM$DD $HH + $FCSTHR hours")
export nYY=`echo $NYMDH | cut -c1-4`
export nMM=`echo $NYMDH | cut -c5-6`
export nDD=`echo $NYMDH | cut -c7-8`
export nHH=`echo $NYMDH | cut -c9-10`

# set paths
export WORKDIR=$project_binary_dir/test
export EXECDIR=${EXECDIR:-$project_binary_dir/bin}
export LANDDA_INPUTS=${LANDDA_INPUTS:-"`dirname $project_source_dir`/inputs"}

# set IODA path
export IODA_BUILD_DIR=${IODA_BUILD_DIR:-"${JEDI_INSTALL}/build"}
export PYTHON_VERSION=`python -c 'import sys; version=sys.version_info[:3]; print("{0}.{1}".format(*version))'`
export PYTHONPATH=$PYTHONPATH:${IODA_BUILD_DIR}/lib/python${PYTHON_VERSION}/pyioda:${IODA_BUILD_DIR}/lib/pyiodaconv

# JEDI directories
export JEDI_EXECDIR=${JEDI_EXECDIR:-"${JEDI_INSTALL}/build/bin"}
export JEDI_STATICDIR=${JEDI_INSTALL}/jedi-bundle/fv3-jedi/test/Data

# set executables
export MPIRUN=${MPIRUN:-`which mpiexec`}
export PYTHON_EXEC=${PYTHON_EXEC:-`which python`}

# configurations
export RES=96
export atmos_forc=era5
export TPATH="$LANDDA_INPUTS/forcing/${atmos_forc}/orog_files/"
export TSTUB="oro_C${RES}.mx100"
export GFSv17=NO
export OBS_TYPES=("GHCN")
export DAtype=letkfoi_snow
export fv3bundle_vn=psl_develop
export B=30  # background error std for LETKFOI
if [ $GFSv17 == "YES" ]; then
    export SNOWDEPTHVAR="snodl"
else
    export SNOWDEPTHVAR="snwdph"
fi

# BASELINE TOL
export TOL=${TOL:-"1e-6"}
