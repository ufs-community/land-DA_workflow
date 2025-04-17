#!/bin/sh

set -xue

# Set other dates
PTIME=$($NDATE -${DATE_CYCLE_FREQ_HR} $PDY$cyc)

YYYY=${PDY:0:4}
MM=${PDY:4:2}
DD=${PDY:6:2}
HH=${cyc}
YYYP=${PTIME:0:4}
MP=${PTIME:4:2}
DP=${PTIME:6:2}
HP=${PTIME:8:2}

#
#####################################################################
# Observation Data Files
#####################################################################
#
if [ "${COLDSTART}" != "YES" ] || [ "${PDY}${cyc}" != "${DATE_FIRST_CYCLE:0:10}" ]; then

  OBSDIR="${OBSDIR:-${FIXlandda}/DA_obs}"
  DATA_GHCN_RAW="${DATA_GHCN_RAW:-${FIXlandda}/DATA_ghcn}"
  
  # GHCN snow depth data
  if [ "${OBS_TYPE}" = "ghcn" ]; then
    # GHCN are time-stamped at 18. If assimilating at 00, need to use previous day's obs, 
    # so that obs are within DA window.
    obs_fn="ghcn_snwd_ioda_${YYYP}${MP}${DP}${HP}.nc"
    obs_dp="${OBSDIR}/GHCN/${YYYY}"
    obs_fp="${obs_dp}/${obs_fn}"
    obs_out_fn="ghcn_snow_${PDY}${cyc}.nc"
  
    # check obs is available
    if [ -f "${obs_fp}" ]; then
      echo "GHCN observation file: ${obs_fp}"
      cp -p "${obs_fp}" "${obs_out_fn}"
      cp -p "${obs_fp}" "${COMOUTobs}/${obs_out_fn}"
    elif [ -f "${obs_dp}/${obs_out_fn}" ]; then
      echo "GHCN observation file: ${obs_dp}/${obs_out_fn}"
      cp -p "${obs_dp}/${obs_out_fn}" .
      cp -p "${obs_dp}/${obs_out_fn}" "${COMOUTobs}/${obs_out_fn}"
    else
      input_ghcn_file="${DATA_GHCN_RAW}/${YYYP}.csv"
      if [ ! -f "${input_ghcn_file}" ]; then
        echo "GHCN raw data path: ${DATA_GHCN_RAW}"
        echo "GHCN raw data file: ${YYYP}.csv"
        err_exit "GHCN raw data file does not exist in designated path !!!"
      fi
      ghcn_station_file="${DATA_GHCN_RAW}/ghcnd-stations.txt"
  
      ${USHlandda}/ghcn_snod2ioda.py -i ${input_ghcn_file} -o ${obs_fn} -f ${ghcn_station_file} -d ${YYYP}${MP}${DP}${HP} -m maskout
      if [ $? -ne 0 ]; then
        err_exit "Generation of GHCN obs file failed !!!"
      fi
      cp -p "${obs_fn}" "${obs_out_fn}"
      cp -p "${obs_fn}" "${COMOUTobs}/${obs_out_fn}"
    fi
  
    ############################################################
    # Observation File Plot
    ############################################################
  
    out_title_base="Land-DA::Obs::GHCN::${PDY}::"
    out_fn_base="landda_obs_ghcn_${PDY}_"
  
    cat > plot_obs_ghcn.yaml <<EOF
work_dir: '${DATA}'
fn_input: '${obs_out_fn}'
out_title_base: '${out_title_base}'
out_fn_base: '${out_fn_base}'
cartopy_ne_path: '${FIXlandda}/NaturalEarth'
PY_LOG_LEVEL: '${PY_LOG_LEVEL}'
EOF
  
    ${USHlandda}/plot_obs_ghcn.py
    if [ $? -ne 0 ]; then
      err_exit "Observation file plot failed"
    fi
  
    # Copy result file to COMOUT
    cp -p ${out_fn_base}* ${COMOUTplot}
  fi  
fi

#
#####################################################################
# DATM Forcing Data Files
#####################################################################
#
if [ "${APP}" = "LND" ]; then
  HHsec=$(( HH * 3600 ))
  HHsec_5d=$(printf "%05d" "${HHsec}")

  if [ "${COLDSTART}" = "YES" ] && [ "${PDY}${cyc}" = "${DATE_FIRST_CYCLE:0:10}" ]; then
    first_date_m1=$($NDATE -24 $DATE_FIRST_CYCLE)
    last_date_p1=$($NDATE 24 $DATE_LAST_CYCLE)
    year_first="${first_date_m1:0:4}"
    month_first="${first_date_m1:4:2}"
    day_first="${first_date_m1:6:2}"
    year_last="${last_date_p1:0:4}"
    month_last="${last_date_p1:4:2}"
    day_last="${last_date_p1:6:2}"
  else  # warm start
    # Extract info from datm restart file
    rfile2="ufs.cpld.datm.r.${YYYY}-${MM}-${DD}-${HHsec_5d}.nc"
    if [ -f "${COMINm1}/${rfile2}" ]; then
      ln -nsf "${COMINm1}/${rfile2}" .
    elif [ -f "${WARMSTART_DIR}/${rfile2}" ]; then
      ln -nsf "${WARMSTART_DIR}/${rfile2}" .
    else
      err_exit "${rfile2} does not exist !!!"
    fi
    ${USHlandda}/datm_rfile_info.py -i ${rfile2} -f ${ATMOS_FORC} -l ${PY_LOG_LEVEL}
    # Read result file
    while IFS= read -r line; do
      year_first=$(echo "$line" | cut -d',' -f1)
      month_first=$(echo "$line" | cut -d',' -f2)
      day_first=$(echo "$line" | cut -d',' -f3)
    done < "first_last_date.txt"
    last_date_p1=$($NDATE 24 $DATE_LAST_CYCLE)
    year_last="${last_date_p1:0:4}"
    month_last="${last_date_p1:4:2}"
    day_last="${last_date_p1:6:2}"
  fi

  if [ "${ATMOS_FORC}" = "gswp3" ]; then
    var_fn_prefix="clmforc.GSWP3.c2011.0.5x0.5"
    gswp3_vars=( "Solr" "Prec" "TPQWL" "ESMFmesh" )
    for var in "${gswp3_vars[@]}" ; do
      if [ "${var}" = "ESMFmesh" ]; then
        var_fp="${DCOMINgswp3}/${var_fn_prefix}.TPQWL.SCRIP.210520_${var}.nc"
        if [ -f ${var_fp} ]; then
          ln -nsf "${var_fp}" ${DATA_DATM}
        else
          err_exit "DATM forcing mesh file ${var_fp} does not exist."
        fi
      else
        given_date="${year_first}-${month_first}-08"
        num_months_m1=$(( (year_last - year_first) * 12 + (month_last - month_first) + 1 ))
        for imon in $( seq 1 $num_months_m1 ) ; do
          idate=$( date -d "$given_date + $((imon-1)) months" +%Y%m )
          iyyyy="${idate:0:4}"
          imm="${idate:4:2}"
          var_fn="${var_fn_prefix}.${var}.${iyyyy}-${imm}.nc"
          var_fp="${DCOMINgswp3}/${var_fn}"
          if [ -f ${var_fp} ]; then
            ln -nsf "${var_fp}" ${DATA_DATM}
          else
            err_exit "DATM forcing data file ${var_fp} does not exist."
          fi
        done
      fi
    done
    topo_fns=( "topodata_0.9x1.SCRIP.210520_ESMFmesh.nc"
               "topodata_0.9x1.25_USGS_070110_stream_c151201.nc"
               "fv1.9x2.5_141008_ESMFmesh.nc" )
    for tfn in "${topo_fns[@]}" ; do
      tfp="${DCOMINgswp3}/${tfn}"
      if [ -f ${tfp} ]; then
        ln -nsf "${tfp}" ${DATA_DATM}
      else
        err_exit "DATM topo file ${tfp} does not exist."
      fi
    done

  elif [ "${ATMOS_FORC}" = "era5" ]; then
    datm_in_mesh_fn="ERA5_mesh.nc"
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
      data_fp="${DCOMINera5}/${data_fn}"
      if [ -f ${data_fp} ]; then
        ln -nsf "${data_fp}" ${DATA_DATM}
      else
        # Create ERA5 forcing file with raw data files
        path_raw_data="${DCOMINera5}/raw_data"
        data_cdate="${iyyyy}${imm}${idd}"
        ${USHlandda}/era5_merge_files.py -i "${path_raw_data}" -c ${data_cdate} -o ${DATA} -l ${PY_LOG_LEVEL}
        cp -p ${data_fn} ${COMOUTdatm}
        ln -nsf "${COMOUTdatm}/${data_fn}" ${DATA_DATM}
      fi
    done
    ln -nsf ${DCOMINera5}/${datm_in_mesh_fn} ${DATA_DATM}
  fi

fi
