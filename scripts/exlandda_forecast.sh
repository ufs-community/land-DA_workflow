#!/bin/sh

set -xue


case $MACHINE in
  "hera")
    run_cmd="srun"
    ;;
  "orion")
    run_cmd="srun"
    ;;
  "hercules")
    run_cmd="srun"
    ;;
  "gaeac6")
    run_cmd="srun"
    ;;
  *)
    run_cmd=`which mpiexec`
    ;;
esac

export MPI_TYPE_DEPTH=20
export OMP_STACKSIZE=512M
# shellcheck disable=SC2125
export OMP_NUM_THREADS=1
export ESMF_RUNTIME_COMPLIANCECHECK=OFF:depth=4
export ESMF_RUNTIME_PROFILE=ON
export ESMF_RUNTIME_PROFILE_OUTPUT="SUMMARY"
export PSM_RANKS_PER_CONTEXT=4
export PSM_SHAREDCONTEXTS=1

NTIME=$($NDATE ${DATE_CYCLE_FREQ_HR} $PDY$cyc)

YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}
YYYYMMDD=${PDY}
nYYYY=${NTIME:0:4}
nMM=${NTIME:4:2}
nDD=${NTIME:6:2}
nHH=${NTIME:8:2}

HHsec=$(( HH * 3600 ))
HHsec_5d=$(printf "%05d" "${HHsec}")
nHHsec=$(( nHH * 3600 ))
nHHsec_5d=$(printf "%05d" "${nHHsec}")

filedate=${YYYY}${MM}${DD}.${HH}0000

# Copy input namelist data / restart files
cp -p "${PARMlandda}/templates/template.noahmptable.tbl" noahmptable.tbl
cp -p "${PARMlandda}/templates/template.fd_ufs.yaml" fd_ufs.yaml
if [ "${APP}" = "LND" ]; then
  mkdir -p INPUT_DATM

  ###############
  # data_table
  ###############
  cp -p "${PARMlandda}/templates/template.${APP}.data_table" data_table
  
  ###########################################
  # datm_in: CDEPS datm input namlist file
  ###########################################
  if [ "${ATMOS_FORC}" = "gswp3" ]; then
    datm_in_datamode="CLMNCEP"
    datm_in_mask_fn="fv1.9x2.5_141008_ESMFmesh.nc"
    datm_in_mesh_fn="fv1.9x2.5_141008_ESMFmesh.nc"
    datm_in_nx_global="144"
    datm_in_ny_global="96"
  elif [ "${ATMOS_FORC}" = "era5" ]; then
    datm_in_datamode="ERA5"
    datm_in_mask_fn="ERA5_mesh.nc"
    datm_in_mesh_fn="ERA5_mesh.nc"
    datm_in_nx_global="1440"
    datm_in_ny_global="721"
  else
    err_exit "Invalid atmospheric forcing option: ATMOS_FORC: ${ATMOS_FORC} !!!"
  fi
  settings="\
    'datm_in_datamode': '${datm_in_datamode}'
    'datm_in_mask_fn': '${datm_in_mask_fn}'
    'datm_in_mesh_fn': '${datm_in_mesh_fn}'
    'datm_in_nx_global': ${datm_in_nx_global}
    'datm_in_ny_global': ${datm_in_ny_global}
  " # End of settings variable
  fp_template="${PARMlandda}/templates/template.${APP}.datm_in"
  fn_namelist="datm_in"
  ${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"

  ######################
  # datm.streams file
  ######################
  data_files01_list=()
  data_files02_list=()
  data_files03_list=()
  if [ "${COLDSTART}" = "YES" ] && [ "${PDY}${cyc}" = "${DATE_FIRST_CYCLE:0:10}" ]; then
    first_date_m1=$($NDATE -24 $DATE_FIRST_CYCLE)
    if [ -z "${DATM_STREAM_FN_LAST_DATE}" ]; then
      last_date_p1=$($NDATE 24 $DATE_LAST_CYCLE)
    else
      last_date_p1=$($NDATE 24 $DATM_STREAM_FN_LAST_DATE)
    fi
    year_first="${first_date_m1:0:4}"
    month_first="${first_date_m1:4:2}"
    day_first="${first_date_m1:6:2}"
    year_last="${last_date_p1:0:4}"
    month_last="${last_date_p1:4:2}"
    day_last="${last_date_p1:6:2}"
  else  # warm start
    # CDEPS restart and pointer files for DATM (LND)
    rfile2="ufs.cpld.datm.r.${YYYY}-${MM}-${DD}-${HHsec_5d}.nc"
    if [ -f "${COMINm1}/${rfile2}" ]; then
      ln -nsf "${COMINm1}/${rfile2}" .
    elif [ -f "${WARMSTART_DIR}/${rfile2}" ]; then
      ln -nsf "${WARMSTART_DIR}/${rfile2}" .
    else
      ln -nsf ${FIXlandda}/restarts/${ATMOS_FORC}/${rfile2} .
    fi
    ls -1 "${rfile2}">rpointer.atm
 
    # Extract info from datm restart file
    ${USHlandda}/datm_rfile_info.py -i ${rfile2} -f ${ATMOS_FORC} -l ${PY_LOG_LEVEL}
    # Read result file
    while IFS= read -r line; do
      year_first=$(echo "$line" | cut -d',' -f1)
      month_first=$(echo "$line" | cut -d',' -f2)
      day_first=$(echo "$line" | cut -d',' -f3)
      year_last=$(echo "$line" | cut -d',' -f4)
      month_last=$(echo "$line" | cut -d',' -f5)
      day_last=$(echo "$line" | cut -d',' -f6)
    done < "first_last_date.txt"
  fi

  if [ "${ATMOS_FORC}" = "gswp3" ]; then
    var_fn_prefix="clmforc.GSWP3.c2011.0.5x0.5"
    gswp3_vars=( "Solr" "Prec" "TPQWL" "ESMFmesh" )
    for var in "${gswp3_vars[@]}" ; do
      given_date="${year_first}-${month_first}-08"
      num_months_m1=$(( (year_last - year_first) * 12 + (month_last - month_first) + 1 ))
      for imon in $( seq 1 $num_months_m1 ) ; do
        idate=$( date -d "$given_date + $((imon-1)) months" +%Y%m )
        iyyyy="${idate:0:4}"
        imm="${idate:4:2}"
        var_fn="${var_fn_prefix}.${var}.${iyyyy}-${imm}.nc"
        if [ "${var}" = "Solr" ]; then
          data_files01_list+=("\"INPUT_DATM/${var_fn}\"")
        elif [ "${var}" = "Prec" ]; then
          data_files02_list+=("\"INPUT_DATM/${var_fn}\"")
        elif [ "${var}" = "TPQWL" ]; then
          data_files03_list+=("\"INPUT_DATM/${var_fn}\"")
        fi
      done
    done
  elif [ "${ATMOS_FORC}" = "era5" ]; then
    data_fn_prefix="ERA5_forcing_"
    data_fn_suffix="_fix.nc"
    first_date="${year_first}-${month_first}-${day_first}"
    last_date="${year_last}-${month_last}-${day_last}"
    second_first=$(date -d "${first_date}" +%s)
    second_last=$(date -d "${last_date}" +%s)
    second_diff=$(( second_last - second_first ))
    num_days=$(( second_diff / (60 * 60 * 24) ))
    for iday in $( seq 0 $num_days ) ; do
      idate=$( date -d "$first_date + $iday days" +%Y%m%d )
      iyyyy="${idate:0:4}"
      imm="${idate:4:2}"
      idd="${idate:6:2}"
      data_fn="${data_fn_prefix}${iyyyy}-${imm}-${idd}${data_fn_suffix}"
      data_files01_list+=("\"INPUT_DATM/${data_fn}\"")
    done
  fi
  year_align="${year_first}"
  settings="\
    'ATMOS_FORC': '${ATMOS_FORC}'
    'year_first': '${year_first}'
    'year_last': '${year_last}'
    'year_align': '${year_align}'
    'data_files01': '${data_files01_list[@]}'
    'data_files02': '${data_files02_list[@]}'
    'data_files03': '${data_files03_list[@]}'
    'datm_in_mesh_fn': '${datm_in_mesh_fn}'
  " # End of settings variable
  fp_template="${PARMlandda}/templates/template.${APP}.datm.streams"
  fn_namelist="datm.streams"
  ${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"

  # soft-link datm input files from shared directory
  ln -nsf ${DATA_DATM}/* INPUT_DATM/.
elif [ "${APP}" = "ATML" ]; then
  ###############
  # field_table
  ###############
  cp -p "${PARMlandda}/templates/template.${APP}.field_table" field_table
  ####################
  # global fix files
  ####################
  ln -nsf ${FIXlandda}/FV3_fix_global/* .
fi

##################
# Set input.nml
##################
if [ "${APP}" = "ATML" ]; then
  if [ "${COLDSTART}" = "YES" ] && [ "${PDY}${cyc}" = "${DATE_FIRST_CYCLE:0:10}" ]; then
    settings="\
      'ATM_IO_LAYOUT_X': ${ATM_IO_LAYOUT_X}
      'ATM_IO_LAYOUT_Y': ${ATM_IO_LAYOUT_Y}
      'ATM_LAYOUT_X': ${ATM_LAYOUT_X}
      'ATM_LAYOUT_Y': ${ATM_LAYOUT_Y}
      'CCPP_SUITE': ${CCPP_SUITE}
      'external_ic': '.true.'
      'make_nh': '.true.'
      'mountain': '.false.'
      'na_init': '1'
      'nggps_ic': '.true.'
      'nstf_name': '2,1,0,0,0'
      'NPZ': ${NPZ}
      'res_p1': ${res_p1}
      'warm_start': '.false.'
    " # End of settings variable
  else
    settings="\
      'ATM_IO_LAYOUT_X': ${ATM_IO_LAYOUT_X}
      'ATM_IO_LAYOUT_Y': ${ATM_IO_LAYOUT_Y}
      'ATM_LAYOUT_X': ${ATM_LAYOUT_X}
      'ATM_LAYOUT_Y': ${ATM_LAYOUT_Y}
      'CCPP_SUITE': ${CCPP_SUITE}
      'external_ic': '.false.'
      'make_nh': '.false.'
      'mountain': '.true.'
      'na_init': '0'
      'nggps_ic': '.false.'
      'nstf_name': '2,0,0,0,0'
      'NPZ': ${NPZ}
      'res_p1': ${res_p1}
      'warm_start': '.true.'
    " # End of settings variable
  fi
  fp_template="${PARMlandda}/templates/template.${APP}.input.nml.${CCPP_SUITE}"
  fn_namelist="input.nml"
  ${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"
else
  cp -p "${PARMlandda}/templates/template.${APP}.input.nml" input.nml
fi

######################
# Set ufs.configure
######################
if [ "${APP}" = "LND" ]; then
  atm_model="datm"
  samegrid_atmlnd=".false."
elif [ "${APP}" = "ATML" ]; then
  atm_model="fv3"
  samegrid_atmlnd=".true."
fi

if [ "${ATMOS_FORC}" = "era5" ]; then
  lnd_precip_partition_option="1"
  lnd_snow_albedo_option="2"
else
  lnd_precip_partition_option="4"
  lnd_snow_albedo_option="1"
fi

if [ "${COLDSTART}" = "YES" ] && [ "${PDY}${cyc}" = "${DATE_FIRST_CYCLE:0:10}" ]; then
  allcomp_read_restart=".false."
  allcomp_start_type="startup"
else
  allcomp_read_restart=".true."
  allcomp_start_type="continue"
fi

nprocs_atm_m1=$(( nprocs_forecast_atm - 1 ))
nprocs_atm_lnd_m1=$(( nprocs_forecast_atm + nprocs_forecast_lnd - 1 ))

settings="\
  'allcomp_read_restart': ${allcomp_read_restart}
  'allcomp_start_type': ${allcomp_start_type}
  'atm_model': ${atm_model}
  'DT_RUNSEQ': ${DT_RUNSEQ}
  'FCSTHR': ${FCSTHR}
  'LND_CALC_SNET': ${LND_CALC_SNET}
  'LND_IC_TYPE': ${LND_IC_TYPE}
  'LND_INITIAL_ALBEDO': ${LND_INITIAL_ALBEDO}
  'LND_LAYOUT_X': ${LND_LAYOUT_X}
  'LND_LAYOUT_Y': ${LND_LAYOUT_Y}
  'LND_OUTPUT_FREQ_SEC': ${LND_OUTPUT_FREQ_SEC}
  'lnd_precip_partition_option': ${lnd_precip_partition_option}
  'lnd_snow_albedo_option': ${lnd_snow_albedo_option}
  'MED_COUPLING_MODE': ${MED_COUPLING_MODE}
  'nprocs_atm_m1': ${nprocs_atm_m1}
  'nprocs_forecast_atm': ${nprocs_forecast_atm}
  'nprocs_atm_lnd_m1': ${nprocs_atm_lnd_m1}
  'samegrid_atmlnd': ${samegrid_atmlnd}
" # End of settings variable

fp_template="${PARMlandda}/templates/template.ufs.configure"
fn_namelist="ufs.configure"
${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"

########################
# Set model_configure
########################
settings="\
  'yyyy': !!str ${YYYY}
  'mm': !!str ${MM}
  'dd': !!str ${DD}
  'hh': !!str ${HH}
  'APP': ${APP}
  'DT_ATMOS': ${DT_ATMOS}
  'FCSTHR': ${FCSTHR}
  'FHROT': ${FHROT}
  'IMO': ${IMO}
  'JMO': ${JMO}
  'OUTPUT_FH': ${OUTPUT_FH}
  'RESTART_INTERVAL': ${RESTART_INTERVAL}
  'WRITE_GROUPS': ${WRITE_GROUPS}
  'WRITE_TASKS_PER_GROUP': ${WRITE_TASKS_PER_GROUP}
" # End of settings variable

fp_template="${PARMlandda}/templates/template.model_configure"
fn_namelist="model_configure"
${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"

###################
# set diag table
###################
settings="\
  'yyyymmdd': !!str ${YYYYMMDD}
  'yyyy': !!str ${YYYY}
  'mm': !!str ${MM}
  'dd': !!str ${DD}
  'hh': !!str ${HH}
" # End of settings variable

fp_template="${PARMlandda}/templates/template.${APP}.diag_table"
fn_namelist="diag_table"
${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"

################################
# Set up RESTART directory
################################
mkdir -p RESTART

if [ "${COLDSTART}" = "NO" ] || [ "${PDY}${cyc}" != "${DATE_FIRST_CYCLE:0:10}" ]; then
  # Set path to directory where restart files exist
  if [ "${COLDSTART}" = "NO" ] && [ "${PDY}${cyc}" = "${DATE_FIRST_CYCLE:0:10}" ]; then
    data_dir="${WARMSTART_DIR}"
  else
    data_dir="${COMINm1}/RESTART"
  fi      
  # CMEPS restart and pointer files
  r_fn="ufs.cpld.cpl.r.${YYYY}-${MM}-${DD}-${HHsec_5d}.nc"
  if [ -f "${data_dir}/${r_fn}" ]; then
    ln -nsf "${data_dir}/${r_fn}" RESTART/.
  else
    err_exit "${data_dir}/${r_fn} file does not exist."
  fi
  ls -1 "./RESTART/${r_fn}">rpointer.cpl

  # NoahMP restart files
  if [ "${DO_FREE_FORECAST}" = "YES" ]; then
    for itile in {1..6}
    do
      ln -nsf "${WARMSTART_DIR}/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${itile}.nc" RESTART/ufs.cpld.lnd.out.${YYYY}-${MM}-${DD}-${HHsec_5d}.tile${itile}.nc
    done
  else
    for itile in {1..6}
    do
      ln -nsf "${COMIN}/ufs_land_restart.anal.${YYYY}-${MM}-${DD}_${HH}-00-00.tile${itile}.nc" RESTART/ufs.cpld.lnd.out.${YYYY}-${MM}-${DD}-${HHsec_5d}.tile${itile}.nc
    done
  fi
fi

#############################
# Set up INPUT directory
#############################
mkdir -p INPUT
cd INPUT

sfc_fns=( "facsf" "maximum_snow_albedo" "slope_type" "snowfree_albedo" "soil_color" \
          "soil_type" "substrate_temperature" "vegetation_greenness" "vegetation_type" )
for ifn in "${sfc_fns[@]}" ; do
  for itile in {1..6};
  do
    ln -nsf "${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}.${ifn}.tile${itile}.nc" .
  done
done

for itile in {1..6}
do
  ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}_oro_data.tile${itile}.nc oro_data.tile${itile}.nc
  ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}_grid.tile${itile}.nc .
done
ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}_mosaic.nc .

if [ "${APP}" = "LND" ]; then
  for itile in {1..6}
  do
    ln -nsf ${FIXlandda}/NOAHMP_IC/ufs-land_C${RES}_init_fields.tile${itile}.nc C${RES}.initial.tile${itile}.nc
  done
elif [ "${APP}" = "ATML" ]; then
  ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}_grid_spec.nc grid_spec.nc
  for itile in {1..6}
  do
    ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}_oro_data_ls.tile${itile}.nc oro_data_ls.tile${itile}.nc
    ln -nsf ${FIXlandda}/FV3_fix_tiled/C${RES}/C${RES}_oro_data_ss.tile${itile}.nc oro_data_ss.tile${itile}.nc
  done
  # GFS IC files for cold start
  if [ "${COLDSTART}" = "YES" ] && [ "${PDY}${cyc}" = "${DATE_FIRST_CYCLE:0:10}" ]; then
    ln -nsf ${COMIN}/gfs_ctrl.nc .
    for itile in {1..6}
    do
      ln -nsf ${COMIN}/gfs_data.tile${itile}.nc .
      ln -nsf ${COMIN}/sfc_data.tile${itile}.nc .
    done
  fi
fi

# Copy restart files only for ATML
if [ "${APP}" = "ATML" ]; then
  if [ "${COLDSTART}" = "NO" ] || [ "${PDY}${cyc}" != "${DATE_FIRST_CYCLE:0:10}" ]; then
    # Set path to directory where restart files exist
    if [ "${COLDSTART}" = "NO" ] && [ "${PDY}${cyc}" = "${DATE_FIRST_CYCLE:0:10}" ]; then
      data_dir="${WARMSTART_DIR}"
    else
      data_dir="${COMINm1}/RESTART"
    fi

    rst_fns=( "ca_data" "fv_core.res" "fv_srf_wnd.res" "fv_tracer.res" "phy_data" )
    for ifn in "${rst_fns[@]}" ; do
      for itile in {1..6};
      do
        r_fp="${data_dir}/${YYYY}${MM}${DD}.${HH}0000.${ifn}.tile${itile}.nc"
        if [ -f "${r_fp}" ]; then
          ln -nsf "${r_fp}" "${ifn}.tile${itile}.nc"
        else
          err_exit "${r_fp} file does not exist."
        fi
      done
      if [ "${ifn}" = "fv_core.res" ]; then
        r_fp="${data_dir}/${YYYY}${MM}${DD}.${HH}0000.${ifn}.nc"
        if [ -f "${r_fp}" ]; then
          ln -nsf "${r_fp}" "${ifn}.nc"
        else
          err_exit "${r_fp} file does not exist."
        fi
      fi
    done
    # link sfc_data from COMIN because they were upated by JEDI Analysis task
    if [ "${PDY}${cyc}" != "${DATE_FIRST_CYCLE:0:10}" ]; then
      data_dir="${COMIN}"
    fi
    for itile in {1..6};
    do
      r_fp="${data_dir}/${YYYY}${MM}${DD}.${HH}0000.sfc_data.tile${itile}.nc"
      if [ -f "${r_fp}" ]; then
        ln -nsf "${r_fp}" "sfc_data.tile${itile}.nc"
      else
        err_exit "${r_fp} file does not exist."
      fi
    done

    # update coupler.res file
    settings="\
  'coupler_calendar': ${COUPLER_CALENDAR}
  'yyyp': !!str ${YYYY}
  'mp': !!str ${MM}
  'dp': !!str ${DD}
  'hp': !!str ${HH}
  'yyyy': !!str ${YYYY}
  'mm': !!str ${MM}
  'dd': !!str ${DD}
  'hh': !!str ${HH}
" # End of settings variable

    fp_template="${PARMlandda}/templates/template.coupler.res"
    fn_namelist="coupler.res"
    ${USHlandda}/fill_jinja_template.py -u "${settings}" -t "${fp_template}" -o "${fn_namelist}"

  fi
fi
cd -

# start runs
echo "Start ufs-cdeps-land model run with TASKS: ${nprocs_forecast}"
export pgm="ufs_model"
. prep_step
${run_cmd} -n ${nprocs_forecast} ${EXEClandda}/$pgm >>$pgmout 2>errfile
export err=$?; err_chk
cp errfile errfile_ufs_model
if [[ $err != 0 ]]; then
  err_exit "ufs_model failed"
fi

###########################
# copy model ouput to COM
###########################

# Copy and link output file to restart for next cycle
for itile in {1..6}
do
  cp -p "${DATA}/ufs.cpld.lnd.out.${nYYYY}-${nMM}-${nDD}-${nHHsec_5d}.tile${itile}.nc" "${COMOUT}/RESTART/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.tile${itile}.nc"
  ln -nsf "${COMOUT}/RESTART/ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.tile${itile}.nc" ${DATA_RESTART}/.
done

# Move land output to COMOUT
lnd_out_freq_hr=$(( LND_OUTPUT_FREQ_SEC / 3600 ))
lnd_fcst_hh=${lnd_out_freq_hr}
while [ ${lnd_fcst_hh} -le ${FCSTHR} ]; do
  lnd_out_date=$($NDATE $lnd_fcst_hh $PDY$cyc)
  lnd_out_yyyy=${lnd_out_date:0:4}
  lnd_out_mm=${lnd_out_date:4:2}
  lnd_out_dd=${lnd_out_date:6:2}
  lnd_out_hh=${lnd_out_date:8:2}
  lnd_out_hh_sec=$(( lnd_out_hh * 3600 ))
  lnd_out_hh_sec_5d=$(printf "%05d" "${lnd_out_hh_sec}")
  lnd_fcst_hh_3d=$(printf "%03d" "${lnd_fcst_hh}")
  # land output files
  for itile in {1..6}
  do
    cp -p "${DATA}/ufs.cpld.lnd.out.${lnd_out_yyyy}-${lnd_out_mm}-${lnd_out_dd}-${lnd_out_hh_sec_5d}.tile${itile}.nc" "${COMOUT}/${NET}.${cycle}.lnd.f${lnd_fcst_hh_3d}.c${RES}.tile${itile}.nc"
  done
  # ufs.cpld.cpl.r files
  cp -p "${DATA}/RESTART/ufs.cpld.cpl.r.${lnd_out_yyyy}-${lnd_out_mm}-${lnd_out_dd}-${lnd_out_hh_sec_5d}.nc" ${COMOUT}/RESTART/.

  lnd_fcst_hh=$(( lnd_fcst_hh + lnd_out_freq_hr ))
done

if [ "${APP}" = "LND" ]; then
  cp -p "${DATA}/ufs.cpld.datm.r.${nYYYY}-${nMM}-${nDD}-${nHHsec_5d}.nc" ${COMOUT}/.
  ln -nsf "${COMOUT}/ufs.cpld.datm.r.${nYYYY}-${nMM}-${nDD}-${nHHsec_5d}.nc" ${DATA_RESTART}/.
elif [ "${APP}" = "ATML" ]; then
  read -ra out_fh <<< "${OUTPUT_FH}"
  out_fh1="${out_fh[0]}"
  out_fh2="${out_fh[1]}"
  if [ "${out_fh2}" = "-1" ]; then
    list_out_fh=$(seq 0 ${out_fh1} ${FCSTHR})
  else
    list_out_fh=${OUTPUT_FH}
  fi
  for ihr in ${list_out_fh}
  do
    ihr_3d=$(printf "%03d" "${ihr}")
    for itile in {1..6}
    do
      cp -p "${DATA}/atmf${ihr_3d}.tile${itile}.nc" "${COMOUT}/${NET}.${cycle}.atm.f${ihr_3d}.c${RES}.tile${itile}.nc"
      cp -p "${DATA}/sfcf${ihr_3d}.tile${itile}.nc" "${COMOUT}/${NET}.${cycle}.sfc.f${ihr_3d}.c${RES}.tile${itile}.nc"
    done
  done
  # RESTART directory
  cp -p "${DATA}/RESTART/${nYYYY}${nMM}${nDD}.${nHH}0000.coupler.res" ${COMOUT}/RESTART/.
  cp -p "${DATA}/RESTART/${nYYYY}${nMM}${nDD}.${nHH}0000.fv_core.res.nc" ${COMOUT}/RESTART/.

  rst_fns=( "ca_data" "fv_core.res" "fv_srf_wnd.res" "fv_tracer.res" "phy_data" "sfc_data" )
  for ifn in "${rst_fns[@]}" ; do
    for itile in {1..6};
    do
      cp -p "${DATA}/RESTART/${nYYYY}${nMM}${nDD}.${nHH}0000.${ifn}.tile${itile}.nc" ${COMOUT}/RESTART/.
    done
  done
  # Set sfc_data to DATA_RESTART to trigger ANALYSIS task in next cycle
  for itile in {1..6};
  do
    cp -p "${COMOUT}/RESTART/${nYYYY}${nMM}${nDD}.${nHH}0000.sfc_data.tile${itile}.nc" ${DATA_RESTART}/.
  done
fi


###########################################################
# WE2E test
###########################################################
if [ "${WE2E_TEST}" == "YES" ]; then
  path_fbase="${FIXlandda}/test_base/we2e_com/${RUN}.${PDY}/RESTART"
  fn_res="ufs_land_restart.${nYYYY}-${nMM}-${nDD}_${nHH}-00-00.tile"
  we2e_log_fp="${LOGDIR}/${WE2E_LOG_FN}"
  
  if [ ! -f "${we2e_log_fp}" ]; then
    touch ${we2e_log_fp}
  fi
  # restart files
  for itile in {1..6}
  do
    ${USHlandda}/compare.py "${path_fbase}/${fn_res}${itile}.nc" "${COMOUT}/RESTART/${fn_res}${itile}.nc" ${WE2E_ATOL} ${we2e_log_fp} "FORECAST" ${filedate} "ufs_land_restart.tile${itile}"
  done
fi

