#!/bin/sh

set -xue

YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}

############################################################
# Stats Plot
############################################################

cp -p ${PARMlandda}/templates/template.plot_hofx.yaml plot_hofx.yaml

# Path to the directory containing the input file
INPUTFP="${DATA_HOFX}"
# Field variable
FIELDVAR="OMA"
# Field Range for scatter plot: [Low,High]
FRLOW=-300
FRHIGH=300
# Number of bins in histogram plot
NBINS=100
# Plot type (scatter/histogram/both)
PLOTTYPE="both"
# Figure title
FIGTITLE="GHCN Snow Depth (mm)::Obs-Ana::${PDY}"
# Prefix of output file name
PREOUTFN="hofx_oma_${PDY}"

sed -i "s|INPUTFP|${INPUTFP}|g" plot_hofx.yaml
sed -i -e "s/XXFIELDVAR/${FIELDVAR}/g" plot_hofx.yaml
sed -i -e "s/XXFRLOW/${FRLOW}/g" plot_hofx.yaml
sed -i -e "s/XXFRHIGH/${FRHIGH}/g" plot_hofx.yaml
sed -i -e "s/XXNBINS/${NBINS}/g" plot_hofx.yaml
sed -i -e "s/XXPLOTTYPE/${PLOTTYPE}/g" plot_hofx.yaml
sed -i -e "s/XXFIGTITLE/${FIGTITLE}/g" plot_hofx.yaml
sed -i -e "s/XXPREOUTFN/${PREOUTFN}/g" plot_hofx.yaml
sed -i -e "s/XXMACHINE/${MACHINE}/g" plot_hofx.yaml

${USHlandda}/hofx_analysis_stats.py
if [[ $? != 0 ]]; then
  echo "FATAL ERROR: Scatter/Histogram plots failed"
  exit 33
fi

# Copy result files to COMOUT
cp -p ${PREOUTFN}* ${COMOUTplot}


############################################################
# Restart Plot
############################################################

nYYYY=${NTIME:0:4}
nMM=${NTIME:4:2}
nDD=${NTIME:6:2}
nHH=${NTIME:8:2}

cp -p ${PARMlandda}/templates/template.plot_restart.yaml plot_restart.yaml

PATH_DATA="${COMIN}"
WORK_DIR="${DATA}"
FN_DATA_BASE="ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.tile"
FN_DATA_EXT=".nc"
SOIL_LEVEL_NUMBER="1"
OUT_TITLE_BASE="Land-DA::restart::${nYYYY}-${nMM}-${nDD}_${nHH}::"
OUT_FN_BASE="landda_out_restart_${nYYYY}-${nMM}-${nDD}_${nHH}_"

sed -i "s|PATH_DATA|${PATH_DATA}|g" plot_restart.yaml
sed -i "s|WORK_DIR|${WORK_DIR}|g" plot_restart.yaml
sed -i -e "s/XXFN_DATA_BASE/${FN_DATA_BASE}/g" plot_restart.yaml
sed -i -e "s/XXFN_DATA_EXT/${FN_DATA_EXT}/g" plot_restart.yaml
sed -i -e "s/XXSOIL_LEVEL_NUMBER/${SOIL_LEVEL_NUMBER}/g" plot_restart.yaml
sed -i -e "s/XXOUT_TITLE_BASE/${OUT_TITLE_BASE}/g" plot_restart.yaml
sed -i -e "s/XXOUT_FN_BASE/${OUT_FN_BASE}/g" plot_restart.yaml
sed -i -e "s/XXMACHINE/${MACHINE}/g" plot_restart.yaml

${USHlandda}/plot_forecast_restart.py
if [[ $? != 0 ]]; then
  echo "FATAL ERROR: Forecast restart plots failed"
  exit 44
fi

# Copy result files to COMOUT
cp -p ${OUT_FN_BASE}* ${COMOUTplot}

