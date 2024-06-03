#!/bin/sh

set -xue


YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}
YYYP=${PTIME:0:4}
MP=${PTIME:4:2}
DP=${PTIME:6:2}
HP=${PTIME:8:2}


cp ${PARMlandda}/templates/template.plot_hofx.yaml plot_hofx.yaml

# Path to the directory containing the input file
INPUTFP="${DATA_HOFX}"
# Field variable
FIELDVAR="OMA"
#
NBINS=100
# Plot type
PLOTTYPE="scatter"
# Figure title
FIGTITLE="GHCN Snow Depth (mm): Obs - Ana"
# Output file name
OUTPUTFN="hofx_oma_scatter.png"

sed -i -e "s/XXINPUTFP/${INPUTFP}/g" plot_hofx.yaml
sed -i -e "s/XXFIELDVAR/${FIELDVAR}/g" plot_hofx.yaml
sed -i -e "s/XXNBINS/${NBINS}/g" plot_hofx.yaml
sed -i -e "s/XXPLOTTYPE/${PLOTTYPE}/g" plot_hofx.yaml
sed -i -e "s/XXFIGTITLE/${FIGTITLE}/g" plot_hofx.yaml
sed -i -e "s/XXOUTPUTFN/${OUTPUTFN}/g" plot_hofx.yaml

${USHlandda}/hofx_analysis_stats.py
if [[ $? != 0 ]]; then
  echo "plotting stats failed"
  exit 13
fi

cp -p ${OUTPUTFN} ${COMOUTplot}
