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

TPATH=${LANDDA_INPUTS}/forcing/${ATMOS_FORC}/orog_files/
YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}
YYYP=${PTIME:0:4}
MP=${PTIME:4:2}
DP=${PTIME:6:2}
HP=${PTIME:8:2}

mem_ens="mem000" 

MEM_WORKDIR=${WORKDIR}/${mem_ens}
MEM_MODL_OUTDIR=${COMOUT}/${mem_ens}
RSTRDIR=${MEM_WORKDIR}
JEDIWORKDIR=${WORKDIR}/mem000/jedi
FILEDATE=${YYYY}${MM}${DD}.${HH}0000

cd $JEDIWORKDIR

OBSDIR=${LANDDA_INPUTS}/DA
################################################
# 2. PREPARE OBS FILES
################################################
for obs in "${OBS_TYPES[@]}"; do
  # get the obs file name
  if [ ${obs} == "GTS" ]; then
    obsfile=$OBSDIR/snow_depth/GTS/data_proc/${YYYY}${MM}/adpsfc_snow_${YYYY}${MM}${DD}${HH}.nc4
    # GHCN are time-stamped at 18. If assimilating at 00, need to use previous day's obs, so that
    # obs are within DA window.
  elif [ $ATMOS_FORC == "era5" ] && [ ${obs} == "GHCN" ]; then
    obsfile=$OBSDIR/snow_depth/GHCN/data_proc/v3/${YYYY}/ghcn_snwd_ioda_${YYYP}${MP}${DP}_jediv7.nc
  elif [ $ATMOS_FORC == "gswp3" ] && [ ${obs} == "GHCN" ]; then
    obsfile=$OBSDIR/snow_depth/GHCN/data_proc/v3/${YYYY}/fake_ghcn_snwd_ioda_${YYYP}${MP}${DP}_jediv7.nc
  elif [ ${obs} == "SYNTH" ]; then
    obsfile=$OBSDIR/synthetic_noahmp/IODA.synthetic_gswp_obs.${YYYY}${MM}${DD}${HH}.nc
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
