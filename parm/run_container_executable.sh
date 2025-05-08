#!/bin/bash

export SINGULARITYENV_FI_PROVIDER=tcp
export SINGULARITY_SHELL=/bin/bash
SINGULARITYBIN=`which singularity`
BINDDIR="/"`pwd | awk -F"/" '{print $2}'`
img=IMAGE
CONTAINERBASE="/"`echo $img | xargs realpath | awk -F"/" '{print $2}'`
cmd=$(basename "$0")
arg="$@"
if [ ! -z "$LANDDAROOT" ]; then
  INPUTBASE="/"`echo $LANDDAROOT | xargs realpath | awk -F"/" '{print $2}'`
  INPUTBIND="-B $INPUTBASE:$INPUTBASE"
else
  INPUTBIND=""
fi
# Remove echo for ndate command as it messes with the PTIME variable 
if [ $cmd != "ndate" ]; then
  echo running: ${SINGULARITYBIN} exec -B $BINDDIR:$BINDDIR -B $CONTAINERBASE:$CONTAINERBASE $INPUTBIND $img $cmd $arg
fi
# Use the unified env python
if [[ $1 =~ "ghcn_snod2ioda.py" ]] || [[ $1 =~ "imsfv3_scf2ioda.py" ]]; then
  export SINGULARITYENV_PREPEND_PATH=/usr/bin
  export SINGULARITYENV_PYTHONPATH="/opt/jedi-bundle/install/lib/python3.10:/opt/spack-stack/spack-stack-1.6.0/envs/unified-env/install/intel/2021.10.0/py-pandas-1.5.3-cw5g2we/lib/python3.10/site-packages:/opt/spack-stack/spack-stack-1.6.0/envs/unified-env/install/intel/2021.10.0/py-python-dateutil-2.8.2-z6hamoo/lib/python3.10/site-packages:/opt/spack-stack/spack-stack-1.6.0/envs/unified-env/install/intel/2021.10.0/py-pytz-2023.3-pjkzken/lib/python3.10/site-packages:/opt/spack-stack/spack-stack-1.6.0/envs/unified-env/install/intel/2021.10.0/py-netcdf4-1.5.8-jx4ron5/lib/python3.10/site-packages:/opt/spack-stack/spack-stack-1.6.0/envs/unified-env/install/intel/2021.10.0/py-cftime-1.0.3.4-7azgx5e/lib/python3.10/site-packages"
fi
# Uncomment the line below when running the ATML experiment
#export SINGULARITYENV_PREPEND_PATH=SINGULARITY_WORKING_DIR/land-DA_workflow/sorc/build/bin:$SINGULARITYENV_PREPEND_PATH
${SINGULARITYBIN} exec -B $BINDDIR:$BINDDIR -B $CONTAINERBASE:$CONTAINERBASE $INPUTBIND $img $cmd $arg

