#!/usr/bin/env python3

###################################################################### CHJ #####
## Name		: plot_analysis_timehistory.py
## Usage	: Plot timehistory of analysis output
## Input files  : analysis_YYYYMMDDHH.log
## NOAA/EPIC
## History ===============================
## V000: 2024/10/14: Chan-Hoo Jeon : Preliminary version
## V001: 2024/10/15: Chan-Hoo Jeon : Add wall-clock time plot
## V002: 2024/10/31: Chan-Hoo Jeon : Fix input log file name issue
## V003: 2025/02/26: Chan-Hoo Jeon : Add h(x) Obs-ana plot
###################################################################### CHJ #####

import os, sys
import logging
import pathlib
import yaml
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.colors as colors
import matplotlib.ticker
import matplotlib as mpl


# Main part (will be called at the end) ============================= CHJ =====
def main():

    yaml_file="plot_timehistory.yaml"
    with open(yaml_file, 'r') as f:
        yaml_data=yaml.load(f, Loader=yaml.FullLoader)
    f.close()

    path_data = yaml_data['path_data']
    work_dir = yaml_data['work_dir']
    fn_data_anal_prefix = yaml_data['fn_data_anal_prefix']
    fn_data_anal_suffix = yaml_data['fn_data_anal_suffix']
    hofx_data_path = yaml_data['hofx_data_path']
    jedi_exe = yaml_data['jedi_exe']
    nprocs_anal = yaml_data['nprocs_anal']
    out_fn_base = yaml_data['out_fn_base']
    OBS_GHCN_SNOW = yaml_data['OBS_GHCN_SNOW']
    OBS_IMS_SNOW = yaml_data['OBS_IMS_SNOW']
    OBS_SFCSNO = yaml_data['OBS_SFCSNO']
    OBS_SMAP = yaml_data['OBS_SMAP']
    OBS_SMOPS = yaml_data['OBS_SMOPS']
    PY_LOG_LEVEL=yaml_data['PY_LOG_LEVEL']

    # Set logging config
    log_level_str = PY_LOG_LEVEL.upper()
    try:
        log_level = getattr(logging, log_level_str)
    except AttributeError:
        log_level_str = "INFO"
        log_level = logging.INFO
        print(f''' WARNING: Invalid log level "{PY_LOG_LEVEL.upper()}", set to INFO.''')
    print(f''' Python Log Level= str: {log_level_str}, attr: {log_level}''')
    logging.basicConfig(format='%(levelname)s::%(pathname)s::L%(lineno)d::%(message)s', level=log_level)

    logging.info(f''' YAML Data: {yaml_data}''')

    nprocs_anal = int(nprocs_anal)

    svar_list = []
    if OBS_GHCN_SNOW == "YES":
        svar_list.append("ghcn_snow")
    if OBS_IMS_SNOW == "YES":
        svar_list.append("ims_snow")
    if OBS_SFCSNO == "YES":
        svar_list.append("sfcsno")
    if OBS_SMAP == "YES":
        svar_list.append("smap_soil_moisture")
    if OBS_SMOPS == "YES":
        svar_list.append("smops_soil_moisture")

    logging.info(f''' svar_list: {svar_list}''')

    # plot time-history
    for svar in svar_list:
        if svar == "ghcn_snow" or svar == "ims_snow" or svar == "sfcsno":
            var_nm = "totalSnowDepth"
        elif svar == "smap_soil_moisture" or svar == "smops_soil_moisture":
            var_nm = "soilMoistureVolumetric" 

        var_dict_anal = get_data_analysis(path_data,fn_data_anal_prefix,fn_data_anal_suffix,jedi_exe,nprocs_anal,var_nm,svar)
        plot_his_omb(var_dict_anal,out_fn_base,work_dir,var_nm,hofx_data_path,svar)


# Get data from files =============================================== CHJ =====
def get_data_analysis(path_data,fn_data_anal_prefix,fn_data_anal_suffix,jedi_exe,nprocs_anal,var_nm,obs_type):

    logging.info(f''' ===== var name: '{var_nm}' ===== obs type: '{obs_type}'==========''')
    # Find files with the sampe prefix
    fp_data_anal_prefix = os.path.join(path_data,fn_data_anal_prefix)
    files = []
    for entry in os.scandir(path_data):
        if entry.is_file() and \
           entry.name.startswith(fn_data_anal_prefix) and \
           entry.name.endswith(fn_data_anal_suffix):
            files.append(entry.path)

    files.sort()
    logging.debug(f''' Files= {files}''')

    if obs_type == "smap_soil_moisture":
        obs_type_nm = "SoilMoistureSMAP"
    elif obs_type == "smops_soil_moisture":
        obs_type_nm = "SoilMoistureSMOPS"
    else:
        obs_type_nm = obs_type

    nobs_qc_prefix = f"QC {obs_type_nm} {var_nm}"
    logging.info(f''' QC prefix for Nobs: {nobs_qc_prefix}''')

    file_date = []
    min_val_final = []
    max_val_final = []
    rms_val_final = []
    min_val_lstm1 = []
    max_val_lstm1 = []
    rms_val_lstm1 = []
    nobs_qc_final = []
    nobs_in_final = []
    for file_fp in files:
        file_date_raw = file_fp.removeprefix(fp_data_anal_prefix)
        file_date_raw = file_date_raw.removesuffix(fn_data_anal_suffix)
        file_date_tmp = f'''{file_date_raw[0:4]}-{file_date_raw[4:6]}-{file_date_raw[6:8]}-{file_date_raw[8:10]}'''
        file_date.append(file_date_tmp)
        logging.info(f''' File date: {file_date_tmp}''')

        min_val_file = []
        max_val_file = []
        rms_val_file = []
        nobs_qc_file = []
        nobs_in_file = []
        with open(file_fp, 'r') as file:
            for line in file:
                if line.startswith(var_nm):
                    line_data_raw = line
                    line_split = line.split('| ')[1].split(' ')
                    #print("Line split=",line_split)
                    min_var = line_split[0].split(':')[0]
                    min_val = line_split[0].split(':')[1]
                    min_val = float(min_val)
                    min_val_file.append(min_val)
                    #print(min_var,"=",min_val,type(min_val))
                    max_var = line_split[1].split(':')[0]
                    max_val = line_split[1].split(':')[1]
                    max_val = float(max_val)
                    max_val_file.append(max_val)
                    #print(max_var,"=",max_val,type(max_val))
                    rms_var = line_split[2].split(':')[0]
                    rms_val = line_split[2].split(':')[1]
                    rms_val = float(rms_val)
                    rms_val_file.append(rms_val)
                    #print(rms_var,"=",rms_val,type(rms_val))

                if line.startswith(nobs_qc_prefix):
                    line_data_raw = line
                    line_split = line.split(': ')[1].split(' ')
                    #print("QC split=",line_split)
                    if len(line_split) == 6 and line_split[4] != "of" and line_split[1] == "passed":
                        nobs_qc_val = int(line_split[0])
                        nobs_qc_file.append(nobs_qc_val)
                        nobs_in_val = int(line_split[4])
                        nobs_in_file.append(nobs_in_val)
                        #print("NOBS ini=",nobs_in_file,", QC=",nobs_qc_file)

        if not min_val_file:
            min_val_final.append(None)
            min_val_lstm1.append(None)
        else:
            min_val_final.append(min_val_file[-1])
            min_val_lstm1.append(min_val_file[-2])

        if not max_val_file:
            max_val_final.append(None)
            max_val_lstm1.append(None)
        else:
            max_val_final.append(max_val_file[-1])
            max_val_lstm1.append(max_val_file[-2])

        if not rms_val_file:
            rms_val_final.append(None)
            rms_val_lstm1.append(None)
        else:
            rms_val_final.append(rms_val_file[-1])
            rms_val_lstm1.append(rms_val_file[-2])

        if not nobs_qc_file:
            nobs_qc_final.append(None)
        else:
            nobs_qc_final.append(nobs_qc_file[-1])

        if not nobs_in_file:
            nobs_in_final.append(None)
        else:
            nobs_in_final.append(nobs_in_file[-1])

    # Create dictionary
    var_dict_anal = {
        "Date": file_date,
        "Min": min_val_final,
        "Max": max_val_final,
        "RMS": rms_val_final,
        "Min_m1": min_val_lstm1,
        "Max_m1": max_val_lstm1,
        "RMS_m1": rms_val_lstm1,
        "nobs_QC": nobs_qc_final,
        "nobs_in": nobs_in_final
    }
    logging.info(f'''DICT= {var_dict_anal}''')

    return var_dict_anal



# Plot time-history of H(x) OMB data ================================ CHJ =====
def plot_his_omb(var_dict_anal,out_fn_base,work_dir,var_nm,hofx_data_path,obs_type):

    dfa = pd.DataFrame(var_dict_anal)

    omb_fn = f'''hofx_omb_timehis_{obs_type}.txt'''
    omb_fp = os.path.join(hofx_data_path, omb_fn)
    with open(omb_fp, 'r') as f:
        lines = f.readlines()
    column_data = [line.strip().split(' ') for line in lines]
    num_columns = len(column_data[0]) if column_data else 0
    columns = [[] for _ in range(num_columns)]
    for row in column_data:
        for i, value in enumerate(row):
            if i>0:
                value = float(value)
            columns[i].append(value)

    logging.info(f''' dfa_date: {dfa['Date']}''')
    logging.info(f''' column 1 data: {columns[1]}''')
    logging.info(f''' column 2 data: {columns[2]}''')
    dfa_date = dfa['Date']
    col_data_1 = columns[1]
    col_data_2 = columns[2]
    if len(dfa_date) == len(col_data_1):
        dfa_date_plot = dfa_date
    else:
        ncol = len(col_data_1)
        dfa_date_plot = dfa_date[:ncol]
        logging.info(f'''plot date: {dfa_date_plot}''')

    obs_type_upper = obs_type.upper()
    out_title_omb = f'''Land-DA::OMB (observation-background)::{obs_type_upper}'''
    out_fn_omb = f'''{out_fn_base}_omb_{obs_type}'''

    txt_fnt=7
    ln_wdth=0.75
    mk_sz=3
    # figsize=(width,height) in inches
    fig, axes = plt.subplots(nrows=3, ncols=1, sharex=True, figsize=(6,6))
    fig.suptitle(out_title_omb,fontsize=txt_fnt+1,y=0.97)

    axes[0].plot(dfa_date_plot,col_data_1,'o-',color='blue',linewidth=ln_wdth,markersize=mk_sz,label='Mean')
    axes[0].set_ylabel('OMB: Mean', fontsize=txt_fnt-1)
    axes[0].tick_params(axis="y",labelsize=txt_fnt-2)
#    axes[0].legend(fontsize=txt_fnt-1, loc='center')
    axes[0].grid(linewidth=0.2)

    axes[1].plot(dfa_date_plot,col_data_2,'s-.',color='red',mfc='none',linewidth=ln_wdth,markersize=mk_sz,label='STD')
    axes[1].set_ylabel('OMB: STDV', fontsize=txt_fnt-1)
    axes[1].tick_params(axis="y",labelsize=txt_fnt-2)
#    axes[1].legend(fontsize=txt_fnt-1, loc='center')
    axes[1].grid(linewidth=0.2)

    axes[2].plot(dfa['Date'],dfa['nobs_in'],'o-',color='blue',linewidth=ln_wdth,markersize=mk_sz,label='N_obs:raw')
    axes[2].plot(dfa['Date'],dfa['nobs_QC'],'s-.',color='red',mfc='none',linewidth=ln_wdth,markersize=mk_sz,label='N_obs:QC')
    axes[2].set_xlabel('Date', fontsize=txt_fnt-1)
    axes[2].set_ylabel('Number of observations', fontsize=txt_fnt-1)
    axes[2].tick_params(axis="x",labelsize=txt_fnt-2)
    axes[2].tick_params(axis="y",labelsize=txt_fnt-2)
    axes[2].legend(fontsize=txt_fnt-1, loc='center right')
    axes[2].grid(linewidth=0.2)

    plt.xticks(rotation=30, ha='right')
    plt.tight_layout()
    # Output figure
    ndpi = 300
    out_file(work_dir,out_fn_omb,ndpi)


# Output file ======================================================= CHJ =====
def out_file(work_dir,out_file,ndpi):
 
    # Output figure
    fp_out = os.path.join(work_dir,out_file)
    plt.savefig(fp_out+'.png',dpi=ndpi,bbox_inches='tight')
    plt.close('all')


# Main call ========================================================= CHJ =====
if __name__=='__main__':
    main()

