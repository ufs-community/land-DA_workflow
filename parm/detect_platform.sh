#!/bin/sh
#
# Detect HPC platforms
#
if [[ -d /scratch3/NAGAPE ]] ; then
  hoststr=$(hostname)
  if [[ "$hoststr" == "ufe"* ]]; then
    PLATFORM="ursa"
  fi
elif [[ -d /work/noaa ]]; then
  hoststr=$(hostname)
  if [[ "$hoststr" == "hercules"* ]]; then
    PLATFORM="hercules"
  else
    PLATFORM="orion"
  fi
elif [[ -d /ncrc ]]; then
  hoststr=$(hostname)
  if [[ "$hoststr" == "gaea6"* ]]; then
    PLATFORM="gaeac6"
  else
    PLATFORM="gaeac5"
  fi
elif [[ -d /glade ]]; then
  PLATFORM="derecho"
else
  PLATFORM="unknown"
fi
MACHINE="${PLATFORM}"

