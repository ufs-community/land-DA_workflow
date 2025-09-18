#!/bin/sh

set -xue

# Set other dates
YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}
cdate="${PDY}${cyc}"

PTIME=$($NDATE -${DATE_CYCLE_FREQ_HR} $PDY$cyc)
YYYP=${PTIME:0:4}
MP=${PTIME:4:2}
DP=${PTIME:6:2}
HP=${PTIME:8:2}

cycle_freq_hr_half=$(( DATE_CYCLE_FREQ_HR / 2 ))
HTIME=$($NDATE -${cycle_freq_hr_half} $PDY$cyc)
yyyy_hf=${HTIME:0:4}
mm_hf=${HTIME:4:2}
dd_hf=${HTIME:6:2}
hh_hf=${HTIME:8:2}

# JCB parameters
driver_do_posterior_observer="false"
driver_do_test_prints="false"
driver_save_posterior_ensemble="false"
driver_save_posterior_mean_increment="true"
driver_update_obs_config_with_geometry_info="false"
final_diagnostics_departures="anlmob"
inflation_mult="1.0"
inflation_rtpp="0.0"
inflation_rtps="0.0"
local_ensemble_da_solver="${JEDI_ALGORITHM^^}"
land_background_time_fv3="${YYYY}${MM}${DD}.${HH}0000"
land_background_time_iso="${YYYY}-${MM}-${DD}T${HH}:00:00Z"
land_fv3jedi_files_path="Data/fv3files"
land_window_begin="${yyyy_hf}-${mm_hf}-${dd_hf}T${hh_hf}:00:00Z"
land_window_length="PT${DATE_CYCLE_FREQ_HR}H"

# Algorithm-specific values
if [ "${JEDI_ALGORITHM}" = "letkf-oi" ]; then
  jedi_algorithm_mod="local_ensemble_da"
  local_ensemble_da_solver="LETKF"
else
  jedi_algorithm_mod="${JEDI_ALGORITHM}"
fi

# Variable name of snow depth
if [ "${FRAC_GRID}" = "YES" ]; then
  snowdepth_vn="snodl"
else
  snowdepth_vn="snwdph"
fi

# Set a list of JEDI analyses
types_jedi_analyses=()
if [ "${do_jedi_snow}" = "YES" ]; then
  types_jedi_analyses+=("snow")
fi
if [ "${do_jedi_soil_moisture}" = "YES" ]; then
  types_jedi_analyses+=("soil_moisture")
fi
echo "${types_jedi_analyses[@]}"

################################################
# Rrun JCB to create JEDI input yaml files
################################################
for jedi_type in "${types_jedi_analyses[@]}"; do

  if [ "${jedi_type}" = "snow" ]; then
    driver_save_posterior_mean="false"
    inc_fn_prefix="snowinc" 
  elif [ "${jedi_type}" = "soil_moisture" ]; then
    driver_save_posterior_mean="true"
    inc_fn_prefix="smcinc"
  fi

  # update jcb-base yaml file
  settings="\
  'FIXlandda': ${FIXlandda}
  'JEDI_ALGORITHM': ${JEDI_ALGORITHM}
  'jedi_algorithm_mod': ${jedi_algorithm_mod}
  'PARMlandda': ${PARMlandda}
  'RES': ${RES}
  'driver_do_posterior_observer': ${driver_do_posterior_observer}
  'driver_do_test_prints': ${driver_do_test_prints}
  'driver_save_posterior_ensemble': ${driver_save_posterior_ensemble}
  'driver_save_posterior_mean': ${driver_save_posterior_mean}
  'driver_save_posterior_mean_increment': ${driver_save_posterior_mean_increment}
  'driver_update_obs_config_with_geometry_info': ${driver_update_obs_config_with_geometry_info}
  'final_diagnostics_departures': ${final_diagnostics_departures}
  'inc_fn_prefix': ${inc_fn_prefix}
  'inflation_mult': ${inflation_mult}
  'inflation_rtpp': ${inflation_rtpp}
  'inflation_rtps': ${inflation_rtps}
  'jedi_type': ${jedi_type}
  'local_ensemble_da_solver': ${local_ensemble_da_solver}
  'land_window_begin': !!str ${land_window_begin}
  'land_window_length': ${land_window_length}
  'land_final_inc_file_path': ./
  'land_fv3jedi_files_path': ${land_fv3jedi_files_path}
  'land_layout_x': 1
  'land_layout_y': 1
  'land_npx_anl': ${res_p1}
  'land_npy_anl': ${res_p1}
  'land_npz_anl': ${NPZ}
  'land_npx_ges': ${res_p1}
  'land_npy_ges': ${res_p1}
  'land_npz_ges': ${NPZ}
  'land_background_path': bkg
  'land_background_time_fv3': !!str ${land_background_time_fv3}
  'land_background_time_iso': !!str ${land_background_time_iso}
  'land_bump_data_dir': berror
  'land_obsdatain_path': obs
  'land_obsdatain_prefix': "obs.${PDY}.${cycle}."
  'land_obsdataout_path': diags
  'land_obsdataout_prefix': "diag."
  'land_obsdataout_suffix': "_${cdate}.nc"
  'snowdepth_vn': ${snowdepth_vn}
  'OBS_GHCN_SNOW': '${OBS_GHCN_SNOW}'
  'OBS_IMS_SNOW': '${OBS_IMS_SNOW}'
  'OBS_SFCSNO': '${OBS_SFCSNO}'
  'OBS_SMAP': '${OBS_SMAP}'
  'OBS_SMOPS': '${OBS_SMOPS}'
" # End of settings variable

  template_fp="${PARMlandda}/jedi/jcb-base_land.yaml.j2"
  jcb_base_fn="jcb-base_${jedi_type}.yaml"
  jcb_base_fp="${DATA}/${jcb_base_fn}"
  jcb_out_fn="jedi_${JEDI_ALGORITHM}_${jedi_type}.yaml"
  ${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${template_fp}" -o "${jcb_base_fp}"
    
  ${USHlandda}/jcb_setup.py -i "${jcb_base_fn}" -o "${jcb_out_fn}" -a "${JEDI_ALGORITHM}" -t "${jedi_type}" -g "${FRAC_GRID}" -l "${PY_LOG_LEVEL}"
    
  if [ $? -ne 0 ]; then
    err_exit "Generation of JEDI YAML file for ${jedi_type} by JCB failed !!!"
  fi
    
  cp -p ${jcb_out_fn} ${COMOUT}

done
