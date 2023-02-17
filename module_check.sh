#!/bin/bash

# Script to ensure required modules are loaded for the land DA system.

# find which machine we are on
if [[ ${HOSTNAME} == *"Orion"* ]]; then
  MACHINE=orion
elif [[ ${HOSTNAME} == *"hfe"* ]]; then
  MACHINE=hera
elif [[ ${USE_SINGULARITY} =~ yes ]]; then
  MACHINE=singularity
fi

# check which modules are required and notify the user if they are not currently loaded in the environment.

env_mods=($(grep -o 'load("[^"]*")' ${CYCLEDIR}/modulefiles/landda_${MACHINE}.intel.lua | sed 's/load("//;s/")//'))

missing_mods=()

for mod in ${env_mods[@]}
do
  if ! module is-loaded "${mod}"; then
     missing_mods+=("${mod}")
  fi
done

if [[ ${#missing_mods[@]} -gt 0 ]]; then
  echo "Error: the following modules are not loaded in the current environment: ${missing_mods[@]}. Please load them via 'module use land-offline_workflow/modulefiles; module load landda_${MACHINE}.intel' and then re-launch do_submit_cycle.sh."
  exit 1
else 
 echo "All modules properly loaded in environment. Continuing!"
 exit 0
fi
