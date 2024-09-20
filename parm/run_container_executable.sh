#!/bin/bash

export SINGULARITYENV_FI_PROVIDER=tcp
export SINGULARITY_SHELL=/bin/bash
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
container_env=$PWD/container.env
echo running: ${SINGULARITYBIN} exec --env-file $container_env -B $BINDDIR:$BINDDIR -B $CONTAINERBASE:$CONTAINERBASE $INPUTBIND $img $cmd $arg
${SINGULARITYBIN} exec --env-file $container_env -B $BINDDIR:$BINDDIR -B $CONTAINERBASE:$CONTAINERBASE $INPUTBIND $img $cmd $arg

