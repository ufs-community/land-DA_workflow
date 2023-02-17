#!/bin/bash

# Script to ensure required modules are loaded, define compiler wrapper env. vars, and set the JEDI bundle install path for the land DA system.

# find which machine we are on
if [[ ${HOSTNAME} == *"Orion"* ]]; then
  MACHINE=orion
elif [[ ${HOSTNAME} == *"hfe"* ]]; then
  MACHINE=hera
elif [[ ${USE_SINGULARITY} =~ yes ]]; then
  MACHINE=singularity
fi

# try to load the modules
module use ${LAND_OFFLINE_WORKFLOW}/modulefiles
module load landda_${MACHINE}.intel

# check which modules are required and notify the user if they are not currently loaded in the environment.

env_mods=($(grep -o 'load("[^"]*")' ${LAND_OFFLINE_WORKFLOW}/modulefiles/landda_${MACHINE}.intel.lua | sed 's/load("//;s/")//'))

for mod in ${env_mods[@]}
do
  if ! module is-loaded "${mod}"; then
     echo "${mod} is not loaded in the current environment. Please load ${mod} and re-submit $0."
  fi
done

