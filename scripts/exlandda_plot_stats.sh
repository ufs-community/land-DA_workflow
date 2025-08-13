#!/bin/sh

set -xue

# Set other dates
NTIME=$($NDATE ${DATE_CYCLE_FREQ_HR} $PDY$cyc)

YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}

nYYYY=${NTIME:0:4}
nMM=${NTIME:4:2}
nDD=${NTIME:6:2}
nHH=${NTIME:8:2}

DO_PLOT_OBS="YES"
DO_PLOT_STATS="YES"
DO_PLOT_TIME_HISTORY="YES"
DO_PLOT_BASIN="NO"

if [ "${DO_FREE_FORECAST}" = "YES" ] && [ "${PDY}${cyc}" != "${DATE_FIRST_CYCLE:0:10}" ]; then
  DO_PLOT_RESTART="NO"
  DO_PLOT_COMBINE_TILES="NO"
else
  DO_PLOT_RESTART="YES"
  DO_PLOT_COMBINE_TILES="YES"
fi

############################################################
# Observation File Plot
############################################################
if [ "${DO_PLOT_OBS}" = "YES" ]; then
  obs_prefix="obs.${PDY}.${cycle}"
  fn_input_ghcn="${obs_prefix}.ghcn_snow.nc"
  fn_input_ims="${obs_prefix}.ims_snow.tm00.nc"
  fn_input_smap="${obs_prefix}.smap_combined.nc"
  fn_input_smops="${obs_prefix}.smops.nc"

  # Soft-link the input file to DATA
  if [ "${OBS_GHCN_SNOW}" = "YES" ]; then
    ln -nsf "${COMINobs}/${fn_input_ghcn}" .
  fi
  if [ "${OBS_IMS_SNOW}" = "YES" ]; then
    ln -nsf "${COMINobs}/${fn_input_ims}" .
  fi
  if [ "${OBS_SMAP}" = "YES" ]; then
    ln -nsf "${COMINobs}/${fn_input_smap}" .
  fi
  if [ "${OBS_SMOPS}" = "YES" ]; then
    ln -nsf "${COMINobs}/${fn_input_smops}" .
  fi

  cat > plot_obs_file.yaml << EOF
work_dir: '${DATA}'
cartopy_ne_path: '${FIXlandda}/NaturalEarth'
fn_input_ghcn: '${fn_input_ghcn}'
fn_input_ims: '${fn_input_ims}'
fn_input_smap: '${fn_input_smap}'
fn_input_smops: '${fn_input_smops}'
OBS_GHCN_SNOW: '${OBS_GHCN_SNOW}'
OBS_IMS_SNOW: '${OBS_IMS_SNOW}'
OBS_SMAP: '${OBS_SMAP}'
OBS_SMOPS: '${OBS_SMOPS}'
PDY: '${PDY}'
PY_LOG_LEVEL: '${PY_LOG_LEVEL}'
EOF

  ${USHlandda}/plot_obs_file.py
  if [ $? -ne 0 ]; then
    err_exit "Observation file plot failed"
  fi

  # Copy result file to COMOUT
  cp -p *.png ${COMOUTplot}
fi

############################################################
# Stats Plot
############################################################
if [ "${DO_PLOT_STATS}" = "YES" ]; then
  # Field Range for scatter plot: [Low,High]
  field_range_low=-200
  field_range_high=200
  # Number of bins in histogram plot
  nbins=100
  # Plot type (scatter/histogram/both)
  plottype="both"

  if [ "${OBS_GHCN_SNOW}" = "YES" ]; then
    cp -p "${COMINhofx}/diag.ghcn_snow_${PDY}${cyc}.nc" ${DATA}
  fi
  if [ "${OBS_IMS_SNOW}" = "YES" ]; then
    cp -p "${COMINhofx}/diag.ims_snow_${PDY}${cyc}.nc" ${DATA}
  fi
  if [ "${OBS_SFCSNO}" = "YES" ]; then
    cp -p "${COMINhofx}/diag.sfcsno_${PDY}${cyc}.nc" ${DATA}
  fi
  if [ "${OBS_SMAP}" = "YES" ]; then
    cp -p "${COMINhofx}/diag.smap_soil_moisture_${PDY}${cyc}.nc" ${DATA}
  fi
  if [ "${OBS_SMOPS}" = "YES" ]; then
    cp -p "${COMINhofx}/diag.smops_soil_moisture_${PDY}${cyc}.nc" ${DATA}
  fi

  cat > plot_hofx.yaml <<EOF
cartopy_ne_path: '${FIXlandda}/NaturalEarth'
cdate: '${YYYY}-${MM}-${DD}-${HH}'
cyc: '${cyc}'
field_range: [${field_range_low},${field_range_high}]
hofx_data_path: '${DATA_HOFX_OMB}'
nbins: ${nbins}
plottype: '${plottype}'
work_dir: '${DATA}'
OBS_GHCN_SNOW: '${OBS_GHCN_SNOW}'
OBS_IMS_SNOW: '${OBS_IMS_SNOW}'
OBS_SFCSNO: '${OBS_SFCSNO}'
OBS_SMAP: '${OBS_SMAP}'
OBS_SMOPS: '${OBS_SMOPS}'
PDY: '${PDY}'
PY_LOG_LEVEL: '${PY_LOG_LEVEL}'
EOF
  
  ${USHlandda}/hofx_analysis_stats.py
  if [ $? -ne 0 ]; then
    err_exit "Scatter/Histogram plots failed"
  fi
  
  # Copy result files to COMOUT
  cp -p "${DATA}/hofx_omb"* ${COMOUTplot}
  cp -p "${DATA_HOFX_OMB}/hofx_omb_timehis"* ${COMOUThofx}
fi


############################################################
# Time-history Plot
############################################################
if [ "${DO_PLOT_TIME_HISTORY}" = "YES" ]; then
  fn_data_anal_prefix="analysis_"
  fn_data_anal_suffix=".log"
  out_fn_base="landda_timehistory"

  cat > plot_timehistory.yaml <<EOF
path_data: '${LOGDIR}'
work_dir: '${DATA}'
fn_data_anal_prefix: '${fn_data_anal_prefix}'
fn_data_anal_suffix: '${fn_data_anal_suffix}'
hofx_data_path: '${DATA_HOFX_OMB}'
jedi_exe: '${JEDI_ALGORITHM}'
nprocs_anal: '${NPROCS_ANALYSIS}'
out_fn_base: '${out_fn_base}'
OBS_GHCN_SNOW: '${OBS_GHCN_SNOW}'
OBS_IMS_SNOW: '${OBS_IMS_SNOW}'
OBS_SFCSNO: '${OBS_SFCSNO}'
OBS_SMAP: '${OBS_SMAP}'
OBS_SMOPS: '${OBS_SMOPS}'
PY_LOG_LEVEL: '${PY_LOG_LEVEL}'
EOF

  ${USHlandda}/plot_analysis_timehistory.py
  if [ $? -ne 0 ]; then
    err_exit "Time-history plots failed"
  fi

  # Copy result files to COMOUT
  cp -p ${out_fn_base}* ${COMOUTplot}
fi


###########################################################
# Plot restart tiles
###########################################################
if [ "${DO_PLOT_RESTART}" = "YES" ]; then
  fn_data_base="ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.tile"
  fn_data_ext=".nc"
  soil_level_number="1"
  out_title_base="Land-DA::restart::${nYYYY}-${nMM}-${nDD}_${nHH}::"
  out_fn_base="landda_out_restart_${nYYYY}-${nMM}-${nDD}_${nHH}_"
  plot_cs_cmap="gist_ncar_r"

  cat > plot_restart.yaml <<EOF
path_data: '${COMIN}/RESTART'
work_dir: '${DATA}'
fn_data_base: '${fn_data_base}'
fn_data_ext: '${fn_data_ext}'
soil_lvl_number: '${soil_level_number}'
OBS_SMAP: '${OBS_SMAP}'
OBS_SMOPS: '${OBS_SMOPS}'
out_title_base: '${out_title_base}'
out_fn_base: '${out_fn_base}'
cartopy_ne_path: '${FIXlandda}/NaturalEarth'
plot_cs_cmap: '${plot_cs_cmap}'
PY_LOG_LEVEL: '${PY_LOG_LEVEL}'
EOF

  ${USHlandda}/plot_forecast_restart.py
  if [ $? -ne 0 ]; then
    err_exit "Forecast restart plots failed"
  fi

  # Copy result files to COMOUT
  cp -p ${out_fn_base}* ${COMOUTplot}
fi


###########################################################
# Combine and plot restart tiles
###########################################################
if [ "${DO_PLOT_COMBINE_TILES}" = "YES" ]; then
  fn_data_base="ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.tile"
  fn_data_ext=".nc"
  soil_level_number="1"
  out_title_base="Land-DA::${nYYYY}-${nMM}-${nDD}_${nHH}::"
  out_fn_base="landda_out_combined_${nYYYY}-${nMM}-${nDD}_${nHH}_"
  # Number of mesh (grid) points in longitudinal direction
  nlon_plot=400
  # Number of mesh (grid) points in latitudinal direction
  nlat_plot=200
  # SciPy griddata methods: linear, nearest, cubic
  griddata_method="nearest"
  # matplolib pcolormesh shading options: flat, nearest, auto, gouraud
  shading_option="auto"

  cat > plot_combine_tiles.yaml <<EOF
path_data: '${COMIN}/RESTART'
work_dir: '${DATA}'
fn_data_base: '${fn_data_base}'
fn_data_ext: '${fn_data_ext}'
soil_lvl_number: '${soil_level_number}'
out_title_base: '${out_title_base}'
out_fn_base: '${out_fn_base}'
cartopy_ne_path: '${FIXlandda}/NaturalEarth'
nlon_plot: ${nlon_plot}
nlat_plot: ${nlat_plot}
griddata_method: '${griddata_method}'
shading_option: '${shading_option}'
PY_LOG_LEVEL: '${PY_LOG_LEVEL}'
EOF

  ${USHlandda}/plot_combine_tiles.py
  if [ $? -ne 0 ]; then
    err_exit "Forecast restart plots failed"
  fi

  # Copy result files to COMOUT
  cp -p ${out_fn_base}* ${COMOUTplot}
fi

###########################################################
# Basin Plot
###########################################################
if [ "${DO_PLOT_BASIN}" = "YES" ]; then
  fn_data_base="ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.tile"
  fn_data_ext=".nc"

  out_title_base="Land-DA::restart:: "
  out_fn_base="landda_basin"

  cat > plot_basin.yaml <<EOF
path_data: '${COMIN}/RESTART'
work_dir: '${DATA}'
fn_data_base: '${fn_data_base}'
fn_data_ext: '${fn_data_ext}'
out_title_base: '${out_title_base}'
out_fn_base: '${out_fn_base}'
DATE_FIRST_CYCLE: '${DATE_FIRST_CYCLE}'
DATE_LAST_CYCLE: '${DATE_LAST_CYCLE}'
OBS_GHCN_SNOW: '${OBS_GHCN_SNOW}'
OBS_IMS_SNOW: '${OBS_IMS_SNOW}'
PY_LOG_LEVEL: '${PY_LOG_LEVEL}'

EOF

  # Run script when the experiment reaches its last day
  if [ "${YYYY}${MM}${DD}${HH}"  ==  "${DATE_LAST_CYCLE}" ]; then 
    # Change basin code here. Default is 4219 - Mississippi River basin
    echo "4219" | ${USHlandda}/plot_basin.py
    if [ $? -ne 0 ]; then
      err_exit "Basin plot failed"
    fi

    # Copy result files to COMOUT
    cp -p ${out_fn_base}* ${COMOUTplot}
  fi
fi
