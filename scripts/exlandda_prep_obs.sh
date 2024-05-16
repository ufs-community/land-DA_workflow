#!/bin/sh

set -ex

############################
# copy restarts to workdir, convert to UFS tile for DA (all members) 

if [[ ${EXP_NAME} == "openloop" ]]; then
  do_jedi="NO"
else
  do_jedi="YES"
  SAVE_TILE="YES"
fi

YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}
YYYP=${PTIME:0:4}
MP=${PTIME:4:2}
DP=${PTIME:6:2}
HP=${PTIME:8:2}

mem_ens="mem000" 

JEDIWORKDIR=${WORKDIR}/mem000/jedi

cd $JEDIWORKDIR

################################################
# 2. PREPARE OBS FILES
################################################
OBSDIR="${OBSDIR:-${FIXlandda}/DA}"
for obs in "${OBS_TYPES[@]}"; do
  # get the obs file name
  if [ ${obs} == "GTS" ]; then
    OBSDIR_SUBDIR="${OBSDIR_SUBDIR:-snow_depth/GTS/data_proc}"
    obsfile="${OBSDIR}/${OBSDIR_SUBDIR}/${YYYY}${MM}/adpsfc_snow_${YYYY}${MM}${DD}${HH}.nc4"
    # GHCN are time-stamped at 18. If assimilating at 00, need to use previous day's obs, so that
    # obs are within DA window.
  elif [ $ATMOS_FORC == "era5" ] && [ ${obs} == "GHCN" ]; then
    OBSDIR_SUBDIR="${OBSDIR_SUBDIR:-snow_depth/GHCN/data_proc/v3}"
    obsfile="${OBSDIR}/${OBSDIR_SUBDIR}/${YYYY}/ghcn_snwd_ioda_${YYYP}${MP}${DP}.nc"
  elif [ $ATMOS_FORC == "gswp3" ] && [ ${obs} == "GHCN" ]; then
    OBSDIR_SUBDIR="${OBSDIR_SUBDIR:-snow_depth/GHCN/data_proc/v3}"
    obsfile="${OBSDIR}/${OBSDIR_SUBDIR}/${YYYY}/ghcn_snwd_ioda_${YYYP}${MP}${DP}.nc"
  elif [ ${obs} == "SYNTH" ]; then
    OBSDIR_SUBDIR="${OBSDIR_SUBDIR:-synthetic_noahmp}"
    obsfile="${OBSDIR}/${OBSDIR_SUBDIR}/IODA.synthetic_gswp_obs.${YYYY}${MM}${DD}${HH}.nc"
  else
    echo "do_landDA: Unknown obs type requested ${obs}, exiting"
    exit 1
  fi

  # check obs are available
  if [[ -e $obsfile ]]; then
    echo "do_landDA: $i observations found: $obsfile"
    ln -fs $obsfile  ${obs}_${YYYY}${MM}${DD}${HH}.nc
  else
    echo "${obs} observations not found: $obsfile"
  fi
done
