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
#
NBINS=100
# Plot type
PLOTTYPE="scatter"
# Figure title
FIGTITLE="GHCN Snow Depth (mm)::Obs-Ana::${PDY}"
# Output file name
OUTPUTFN="hofx_oma_${PLOTTYPE}_${PDY}.png"

sed -i "s|INPUTFP|${INPUTFP}|g" plot_hofx.yaml
sed -i -e "s/XXFIELDVAR/${FIELDVAR}/g" plot_hofx.yaml
sed -i -e "s/XXNBINS/${NBINS}/g" plot_hofx.yaml
sed -i -e "s/XXPLOTTYPE/${PLOTTYPE}/g" plot_hofx.yaml
sed -i -e "s/XXFIGTITLE/${FIGTITLE}/g" plot_hofx.yaml
sed -i -e "s/XXOUTPUTFN/${OUTPUTFN}/g" plot_hofx.yaml

${USHlandda}/hofx_analysis_stats.py
if [[ $? != 0 ]]; then
  echo "Scatter Plot failed"
  exit 33
fi

############################################################
# Histogram Plot
############################################################

cp ${PARMlandda}/templates/template.plot_hofx.yaml plot_hofx.yaml

# Path to the directory containing the input file
INPUTFP="${DATA_HOFX}"
# Field variable
FIELDVAR="OMA"
#
NBINS=100
# Plot type
PLOTTYPE="histogram"
# Figure title
FIGTITLE="GHCN Snow Depth (mm)::Obs-Ana::${PDY}"
# Output file name
OUTPUTFN="hofx_oma_${PLOTTYPE}_${PDY}.png"

sed -i "s|INPUTFP|${INPUTFP}|g" plot_hofx.yaml
sed -i -e "s/XXFIELDVAR/${FIELDVAR}/g" plot_hofx.yaml
sed -i -e "s/XXNBINS/${NBINS}/g" plot_hofx.yaml
sed -i -e "s/XXPLOTTYPE/${PLOTTYPE}/g" plot_hofx.yaml
sed -i -e "s/XXFIGTITLE/${FIGTITLE}/g" plot_hofx.yaml
sed -i -e "s/XXOUTPUTFN/${OUTPUTFN}/g" plot_hofx.yaml

${USHlandda}/hofx_analysis_stats.py
if [[ $? != 0 ]]; then
  echo "Histogram Plot failed"
  exit 34
fi


# Copy result files to COMOUT
cp -p ${OUTPUTFN} ${COMOUTplot}
