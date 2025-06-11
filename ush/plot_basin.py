#!/usr/bin/env python3

################################################################################
## Name		: plot_basin.py
## Usage	: Plot variable (default: snow depth) for a specific basin (default: Mississippi River) 
##                for the entire experiment length. Meaning this script only runs for the last cycle. 
##                See land-DA_workflow/scripts/exlandda_plot_stats.sh for configuration and to update basin. 
## Input files  : ufs_land_restart.YYYY-MM-DD_hh-mm-ss.tile#.nc
## NOAA/EPIC
## History =====================================================
##  V000: 2025/06/09: Edward Snyder : Preliminary version 
################################################################################

import os, sys
import logging
import math
import yaml
import numpy as np
import netCDF4 as nc
import matplotlib.pyplot as plt
import matplotlib.colors as colors
from datetime import datetime, timedelta

# Main part of script (called at the end)
def main():

    global num_tiles

    yaml_file = "plot_basin.yaml"
    with open(yaml_file, 'r') as f:
        yaml_data = yaml.load(f, Loader=yaml.FullLoader)
    f.close()
    
    path_data = yaml_data['path_data']
    work_dir = yaml_data['work_dir']
    fn_data_base = yaml_data['fn_data_base']
    fn_data_ext = yaml_data['fn_data_ext']
    out_title_base = yaml_data['out_title_base']
    out_fn_base = yaml_data['out_fn_base']
    first_date = yaml_data['DATE_FIRST_CYCLE']
    last_date = yaml_data['DATE_LAST_CYCLE']
    OBS_GHCN_SNOW = yaml_data['OBS_GHCN_SNOW']
    OBS_IMS_SNOW = yaml_data['OBS_IMS_SNOW']
    PY_LOG_LEVEL = yaml_data['PY_LOG_LEVEL']
    
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

    # NOTE: The mask variable needs to be first in this list since the code expects that
    var_list = ["mask", "snwdph"]
    # Number of tiles
    num_tiles = 6
 
    # Read Basin file
    # NOTE: Only reads in on Hera
    # TODO: Expand to other platforms
    BasinPath = "/scratch2/NCEPDEV/land/data/evaluation/basins/C96/GRDC_C96.nc"
    with nc.Dataset(BasinPath, "r") as ds:
        basin = ds.variables["basins"][:]
        logging.info(f"Lenth of basins variable is {basin.shape}")
        
    # Get Basin code
    print("Valid basin codes are the following:")
    basin_mask_codes = {
      3203: "Amazon",
      4209: "Colorado",
      4405: "Colorado_River",
      4406: "Columbia (NA)",
      2108: "Ob",
      2106: "Lena (Russia)",
      4219: "Mississippi (NA)",
      1209: "Congo",
      1229: "Nile",
      4123: "Mackenzie (NA)",
      2433: "Yangtze",
      2434: "Yellow",
      4435: "Yukon (NA)",
      5309: "Murray",
      6202: "Danube (EU)",
      6242: "Rhine (EU)",
      6243: "Rhone (EU)",
      6903: "Volga (Asia)",
      2401: "Armur (Asia)",
      2117: "Yenisey (Asia)"
    }
    for key, value in basin_mask_codes.items():
            print(f"{key} - {value}")

    # NOTE: Default basin code is 4219 - Mississippi, which is set in the exlandda_plot_stats.sh
    target_basin = int(input("Enter a code value for the target basin: "))

    # Check if target basin is valid
    if target_basin not in basin_mask_codes:
        logging.info(f"{target_basin} is not a valid basin code. Exiting!")
        sys.exit(1)

    # Get simulated days to loop through
    sim_days = abs((datetime.strptime(last_date, "%Y%m%d%H") - datetime.strptime(first_date, "%Y%m%d%H")).days)
    # Range function is not inclusive 
    sim_days = sim_days + 1 
    
    # Create an empty list to contain the variables that are being plotted
    basin_data_list = []

    # Loop through experiment days
    start_date = datetime.strptime(first_date, "%Y%m%d%H")
    for sim_day in range(sim_days):
        # Set path and file name dates
        new_date = start_date + timedelta(days=sim_day)
        path_date_fmt = (new_date).strftime("%Y%m%d")
        file_date_fmt = new_date + timedelta(days=1)
        # Create the path and file name structures
        path_parts = path_data.split('/')
        sim_day_path = "{}/landda.{}/{}".format(os.sep.join(path_parts[:-2]), path_date_fmt, path_parts[-1])
        fn_parts = fn_data_base.split(".")
        sim_day_fn = "{}.{}.{}".format(fn_parts[0], file_date_fmt.strftime("%Y-%m-%d_%H-%M-%S"), fn_parts[2])
        
        # Get variable data based on basin code
        data_out = get_basin_data(num_tiles, sim_day_fn, fn_data_ext, sim_day_path, var_list, basin, target_basin)
        # Append data to list
        basin_data_list.append(data_out)

    # Exit if basin data doesn't exist
    logging.info(f"basin_data_list: {basin_data_list}")
    if max(basin_data_list) == 0:
        logging.info(f"Found no {var_list[1]} variable in target_basin: {target_basin} - {basin_mask_codes[target_basin]}. Exiting safely!")
        sys.exit(0)
    
    # Plot the data
    plot_data(basin_data_list, OBS_GHCN_SNOW, OBS_IMS_SNOW, out_title_base, out_fn_base, basin_mask_codes, target_basin, start_date, work_dir)

def get_basin_data(num_tiles, sim_day_fn, fn_data_ext, sim_day_path, var_list, basin, target_basin):

    # Init variables
    it = 0
    snow_depth_values = []  # array for averaging
    basin_index = 0
    # Loop through 6 tiles
    for it in range(num_tiles):
       itp = it + 1
       fn_data = sim_day_fn + str(itp) + fn_data_ext
       fp_data = os.path.join(sim_day_path, fn_data)
       try: 
           data_raw = nc.Dataset(fp_data)
       except: 
           raise Exception('Could NOT find the file', fp_data)
       logging.info(f"File name is {fp_data}")
       with nc.Dataset(fp_data, "r") as ds:
           mask = ds.variables[var_list[0]][0, :, :]
           snowd = ds.variables[var_list[1]][0, :, :]
           dim = mask.shape
           logging.info(f"Shape of the mask variable is {dim}")
           if it == 0:
              basinGLB=np.zeros((num_tiles,dim[0], dim[1]))
           # Start filling the basinGLB array
           for i in range(dim[0]):
             for j in range(dim[1]):
                 if mask[i, j] == 1:
                   current_basin = basin[basin_index]
                   basinGLB[it, i, j] = current_basin
                   if current_basin == target_basin and snowd[i,j] < 1.e+20:
                       logging.info(f"Basin {current_basin}, tile is {itp}, \n i= {i}, j={j} \n")
                       snow_depth_values.append(snowd[i, j])
                   basin_index +=1
    snow_depth_values = np.array(snow_depth_values)
    average_snow = np.mean(snow_depth_values)
    logging.info(f"Average snow depth for basin {target_basin} is {average_snow} m")
    logging.info(f"Current basin_index is {basin_index} ")

    return average_snow

def plot_data(basin_data_list, OBS_GHCN_SNOW, OBS_IMS_SNOW, out_title_base, out_fn_base, basin_mask_codes, target_basin, start_date, work_dir):

    # Define plot dimensions
    plt.figure(figsize=(12,8))
    ax1 = plt.subplot(1, 1, 1)
    # Ensure x and y heights are divisible by 5
    x_height = math.ceil(len(basin_data_list) / 5) * 5
    y_height = math.ceil(max(basin_data_list) / 5) * 5
    ax1.set_ylim(0.0, y_height)
    ax1.set_xlim(-1, x_height)
    
    # Set obs label 
    if OBS_GHCN_SNOW == "YES":
        obs_label = "GHCN"
    if OBS_IMS_SNOW == "YES":
        obs_label = "IMS"

    # Set labels, title, and filename
    plot_date = start_date + timedelta(days=1)
    label_date = plot_date.strftime("%d %b %Y")
    plot_fn_date =  plot_date.strftime("%Y%m%d")
    x_label = "Simulation day since {}".format(label_date)
    plot_title = "{} {} River Basin".format(out_title_base, basin_mask_codes[target_basin])
    # TODO: think about file name Drop date from out_fn_base
    plot_fn = "{}_{}_{}_{}.png".format(out_fn_base, basin_mask_codes[target_basin].replace(" (", "-").replace(")", ""), plot_fn_date, obs_label.lower())

    # Plot data
    ax1.plot(basin_data_list, 'o-', color='blue', label=obs_label)
    # TODO: figure out units for ghcn obs. Pretty sure it is M
    ax1.set_ylabel("Snow Depth (M)", fontsize=20)
    ax1.set_xlabel(x_label, fontsize=20)
    ax1.set_title(plot_title, pad=20, fontsize=20)
    ax1.legend()
    plt.tight_layout()
    logging.info(f"Saving {plot_fn} to {work_dir}")
    plt.savefig(os.path.join(work_dir, plot_fn))
    plt.close()

if __name__=="__main__":
    main()

