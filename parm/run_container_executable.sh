#!/bin/bash

# Setting variables
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

# Set env file based on conditions
if [[ $1 =~ "ghcn_snod2ioda.py" ]] || [[ $1 =~ "imsfv3_scf2ioda.py" ]] || [[ $1 =~ "smops_ssm2ioda.py" ]]; then
  env_file_name="landda-py.env"
elif [[ "${APP}" == "ATML" ]]; then
  env_file_name="landda-atml.env"
else 
  env_file_name="landda.env"
fi

# Create singularity exec cmd
sing_exec_cmd="${SINGULARITYBIN} exec --env-file SINGULARITY_WORKING_DIR/land-DA_workflow/parm/${env_file_name} -B $BINDDIR:$BINDDIR -B $CONTAINERBASE:$CONTAINERBASE $INPUTBIND $img $cmd $arg"

# Remove echo for ndate command as it messes with the PTIME variable
if [ $cmd != "ndate" ]; then
  echo "Running: $sing_exec_cmd"
fi

# Run singularity cmd
$sing_exec_cmd
