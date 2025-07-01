#!/usr/bin/env python3

###################################################################### CHJ #####
## Name		: smap_ioda_concat_files.py
## Usage	: Run multiple SMAP_ioda and concatenate files for a specific date
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
import glob
import shutil
from netCDF4 import Dataset


# Main part (will be called at the end) ============================= CHJ =====
def main():

    yaml_file="smap_ioda_concat.yaml"
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
        # Run IODA converting script
        command = [sys.executable,f'{USHlandda}/smap_ssm2ioda.py','-i',f'{ifn}','-o',f'{smap_out_ifn}','--maskMissing']
        result = subprocess.run(command, capture_output=True, text=True)
        logging.debug(f''' IODA converter stdout: {result.stdout}''')
        if result.returncode != 0:
            logging.error(f''' Error executing script: {ifn_time} : {result.stderr}''')

    # Concatenate smap_ioda files
    file_list = sorted(glob.glob("smap_ioda_*.nc"))
    out_ds = Dataset(obs_out_fn_smap, 'w', format="NETCDF4")
    concat_dim = "Location"    
    group_names = ["MetaData", "ObsError", "ObsValue", "PreQC"]
    
    root_vars = {}         # var_name -> list of arrays
    root_var_info = {}     # var_name -> dict with dims, dtype, attrs
    group_vars = {g: {} for g in group_names}  # group -> var_name -> list of arrays
    group_var_info = {g: {} for g in group_names}
    dim_sizes = {}         # static dimension sizes
    
    # Read and collect data
    for i, path in enumerate(file_list):
        logging.info(f''' Reading {i+1}/{len(file_list)}: {os.path.basename(path)}''')
        ds = Dataset(path, "r")
    
        # Root variables
        for vname, var in ds.variables.items():
            if concat_dim not in var.dimensions:
                continue
            if vname not in root_vars:
                root_vars[vname] = []
                root_var_info[vname] = {
                    "dims": var.dimensions,
                    "dtype": var.datatype,
                    "attrs": {a: var.getncattr(a) for a in var.ncattrs()}
                }
            root_vars[vname].append(var[:])
    
        # Fixed dimensions (non-unlimited) from first file only
        if i == 0:
            for d in ds.dimensions:
                if d == concat_dim:
                    dim_sizes[d] = None  # unlimited
                else:
                    dim_sizes[d] = len(ds.dimensions[d])
    
        # Group variables (shaped along Location)
        for gname in group_names:
            if gname not in ds.groups:
                continue
            g = ds.groups[gname]
            for vname, var in g.variables.items():
                if concat_dim not in var.dimensions:
                    continue
                if vname not in group_vars[gname]:
                    group_vars[gname][vname] = []
                    group_var_info[gname][vname] = {
                        "dims": var.dimensions,
                        "dtype": var.datatype,
                        "attrs": {a: var.getncattr(a) for a in var.ncattrs()}
                    }
                group_vars[gname][vname].append(var[:])
    
        ds.close()
    
    # Dimensions
    for d, size in dim_sizes.items():
        out_ds.createDimension(d, size)
    
    # Root variables
    for vname, arrays in root_vars.items():
        data = np.concatenate(arrays, axis=0)
        info = root_var_info[vname]
        var = out_ds.createVariable(vname, info["dtype"], info["dims"], zlib=True)
        var.setncatts(info["attrs"])
        var[:] = data
    
    # Group variables
    for gname in group_names:
        g = out_ds.createGroup(gname)
        for vname, arrays in group_vars[gname].items():
            data = np.concatenate(arrays, axis=0)
            info = group_var_info[gname][vname]
            var = g.createVariable(vname, info["dtype"], info["dims"], zlib=True)
            var.setncatts(info["attrs"])
            var[:] = data
    
    out_ds.close()    
    logging.info(f''' The combined SMAP data file {obs_out_fn_smap} has been created successfully !!!''')    



# Main call ========================================================= CHJ =====
if __name__=='__main__':
    main()

