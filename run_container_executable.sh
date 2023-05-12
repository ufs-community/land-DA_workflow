#!/bin/bash

export SINGULARITYENV_FI_PROVIDER=tcp
export SINGULARITY_SHELL=/bin/bash
BINDDIR="/"`pwd | awk -F"/" '{print $2}'`
CONTAINERLOC=${EPICCONTAINERS:-${HOME}}
img=${img:-${CONTAINERLOC}/ubuntu20.04-intel-ue-landda-v1.1.0.img}
CONTAINERBASE="/"`echo $img | xargs realpath | awk -F"/" '{print $2}'`
cmd=$(basename "$0")
arg="$@"
if [ ! -z "$LANDDA_INPUTS" ]; then
  INPUTBASE="/"`echo $LANDDA_INPUTS | xargs realpath | awk -F"/" '{print $2}'`
  INPUTBIND="-B $INPUTBASE:$INPUTBASE"
else
  INPUTBIND=""
fi
echo running: ${SINGULARITYBIN} exec $img $cmd $arg
${SINGULARITYBIN} exec -B $BINDDIR:$BINDDIR -B $CONTAINERBASE:$CONTAINERBASE $INPUTBIND $img $cmd $arg

