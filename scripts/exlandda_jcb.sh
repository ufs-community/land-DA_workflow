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
driver_save_posterior_mean="false"
driver_save_posterior_mean_increment="true"
driver_update_obs_config_with_geometry_info="false"
final_diagnostics_departures="anlmob"
inflation_mult="1.0"
inflation_rtpp="0.0"
inflation_rtps="0.0"
local_ensemble_da_solver="${JEDI_ALGORITHM^^}"
snow_background_time_fv3="${YYYY}${MM}${DD}.${HH}0000"
snow_background_time_iso="${YYYY}-${MM}-${DD}T${HH}:00:00Z"
snow_fv3jedi_files_path="Data/fv3files"
snow_window_begin="${yyyy_hf}-${mm_hf}-${dd_hf}T${hh_hf}:00:00Z"
snow_window_length="PT${DATE_CYCLE_FREQ_HR}H"

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
  'inflation_mult': ${inflation_mult}
  'inflation_rtpp': ${inflation_rtpp}
  'inflation_rtps': ${inflation_rtps}
  'local_ensemble_da_solver': ${local_ensemble_da_solver}
  'snow_window_begin': !!str ${snow_window_begin}
  'snow_window_length': ${snow_window_length}
  'snow_final_inc_file_path': ./
  'snow_fv3jedi_files_path': ${snow_fv3jedi_files_path}
  'snow_layout_x': 1
  'snow_layout_y': 1
  'snow_npx_anl': ${res_p1}
  'snow_npy_anl': ${res_p1}
  'snow_npz_anl': ${NPZ}
  'snow_npx_ges': ${res_p1}
  'snow_npy_ges': ${res_p1}
  'snow_npz_ges': ${NPZ}
  'snow_background_path': bkg
  'snow_background_time_fv3': !!str ${snow_background_time_fv3}
  'snow_background_time_iso': !!str ${snow_background_time_iso}
  'snow_bump_data_dir': berror
  'snow_obsdatain_path': obs
  'snow_obsdatain_prefix': "obs.${PDY}.${cycle}."
  'snow_obsdataout_path': diags
  'snow_obsdataout_prefix': "diag."
  'snow_obsdataout_suffix': "_${cdate}.nc"
  'snowdepth_vn': ${snowdepth_vn}
  'OBS_GHCN_SNOW': '${OBS_GHCN_SNOW}'
  'OBS_IMS_SNOW': '${OBS_IMS_SNOW}'
  'OBS_SFCSNO': '${OBS_SFCSNO}'
" # End of settings variable

template_fp="${PARMlandda}/jedi/jcb-base_snow.yaml.j2"
jcb_base_fn="jcb-base_snow.yaml"
jcb_base_fp="${DATA}/${jcb_base_fn}"
jcb_out_fn="jedi_${JEDI_ALGORITHM}_snow.yaml"
${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${template_fp}" -o "${jcb_base_fp}"

${USHlandda}/jcb_setup.py -i "${jcb_base_fn}" -o "${jcb_out_fn}" -a "${JEDI_ALGORITHM}" -g "${FRAC_GRID}" -l "${PY_LOG_LEVEL}"

if [ $? -ne 0 ]; then
  err_exit "Generation of JEDI YAML file by JCB failed !!!"
fi

cp -p ${jcb_out_fn} ${COMOUT}
