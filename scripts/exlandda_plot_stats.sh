#!/bin/sh

set -xue

############################################################
# Scatter Plot
############################################################

cp ${PARMlandda}/templates/template.plot_hofx.yaml plot_hofx.yaml

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

${USHlandda}/hofx_analysis_stats.py
if [[ $? != 0 ]]; then
  echo "Scatter/Histogram plots failed"
  exit 33
fi

# Copy result files to COMOUT
cp -p ${PREOUTFN}* ${COMOUTplot}
