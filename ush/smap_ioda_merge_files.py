#!/usr/bin/env python3

###################################################################### CHJ #####
## Name		: smap_ioda_merge_files.py
## Usage	: Run multiple SMAP_ioda and merge files for a specific date
## Input files  : SMAP raw H5 files
## NOAA/EPIC
## History ===============================
## V000: 2025/06/23: Chan-Hoo Jeon : Preliminary version
###################################################################### CHJ #####

import os, sys
import logging
import pathlib
import yaml
import numpy as np
import subprocess


# Main part (will be called at the end) ============================= CHJ =====
def main():

    yaml_file="smap_ioda_merge.yaml"
    with open(yaml_file, 'r') as f:
        yaml_data=yaml.load(f, Loader=yaml.FullLoader)
    f.close()

    fn_smap_prefix = yaml_data['fn_smap_prefix']
    fn_smap_suffix = yaml_data['fn_smap_suffix']
    obs_out_fn_smap = yaml_data['obs_out_fn_smap']
    pdy_hf = yaml_data['pdy_hf']
    smap_raw_dir = yaml_data['smap_raw_dir']
    work_dir = yaml_data['work_dir']
    PDY = yaml_data['PDY']
    cyc = yaml_data['cyc']
    PY_LOG_LEVEL=yaml_data['PY_LOG_LEVEL']
    USHlandda=yaml_data['USHlandda']

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

    # Find SMAP raw data files for the date
    files = []
    for entry in os.scandir(smap_raw_dir):
        if entry.is_file() and entry.name.startswith(fn_smap_prefix) and \
           entry.name.endswith(fn_smap_suffix):
            files.append(entry.path)

    files.sort()
    logging.info(f''' SMAP input raw files: {files}''')

    # Convert raw data files one by one
    for ifn in files:
        ifn_tmp = ifn.removeprefix(fn_smap_prefix)
        ifn_tmp = ifn_tmp.removesuffix(fn_smap_suffix)
        ifn_tmp = ifn_tmp.split('_')[-3]
        ifn_pdy = ifn_tmp[:8]
        ifn_time = ifn_tmp.removeprefix(f'{ifn_pdy}T')
        ifn_hhmm = ifn_time[:4]
        smap_out_ifn = f'''smap_ioda_{ifn_pdy}_{ifn_hhmm}.nc'''
        logging.info(f''' SMAP raw file time: {ifn_time}, hhmm: {ifn_hhmm}''')
        command = [sys.executable,f'{USHlandda}/smap_ssm2ioda.py','-i',f'{ifn}','-o',f'{smap_out_ifn}','--maskMissing']
        result = subprocess.run(command, capture_output=True, text=True)
        logging.debug(f''' IODA converter stdout: {result.stdout}''')
        if result.returncode != 0:
            logging.error(f''' Error executing script: {ifn_time} : {result.stderr}''')

    # Merge smap_ioda files



# Main call ========================================================= CHJ =====
if __name__=='__main__':
    main()

