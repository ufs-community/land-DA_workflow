#!/usr/bin/env python3

###################################################################### CHJ #####
## Name		  : sfc_data_replace_var.py
## Usage	  : Replace variables of sfc_data files with those of JEDI output
## NOAA/EPIC
## History ===============================
## V000: 2025/07/09: Chan-Hoo Jeon : Preliminary version
###################################################################### CHJ #####

import os
import sys
import logging
import yaml
import xarray as xr
import numpy as np
import matplotlib.pyplot as plt


# Main part (will be called at the end) ============================= CHJ =====
def main():

    yaml_file = "sfc_replace_var.yaml"
    with open(yaml_file, 'r') as f:
        yaml_data = yaml.load(f, Loader=yaml.FullLoader)
    f.close()

    work_dir = yaml_data['work_dir']
    fn_data_base = yaml_data['fn_data_base']
    sfc_data_fn_suffix = yaml_data['sfc_data_fn_suffix']
    jedi_out_fn_prefix = yaml_data['jedi_out_fn_prefix']
    jedi_out_fn_suffix = yaml_data['jedi_out_fn_suffix']
    new_sfc_data_fn_suffix = yaml_data['new_sfc_data_fn_suffix']
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
   
    var_list = ["smc"]

    num_tiles = 6
    for it in range(num_tiles):
        itp = it+1
        # Input and output file name
        sfc_data_fn = fn_data_base+str(itp)+sfc_data_fn_suffix
        jedi_out_fn = jedi_out_fn_prefix+fn_data_base+str(itp)+jedi_out_fn_suffix
        new_sfc_data_fn = fn_data_base+str(itp)+new_sfc_data_fn_suffix
        # Path to input files
        sfc_data_fp = os.path.join(work_dir, sfc_data_fn)
        jedi_out_fp = os.path.join(work_dir, jedi_out_fn)
        logging.info(f''' File 1: {sfc_data_fp}''')
        logging.info(f''' File 2: {jedi_out_fp}''')
        # Open the NetCDF datasets
        try:
            ds1 = xr.open_dataset(sfc_data_fp)
          #  print(ds1)
            ds2 = xr.open_dataset(jedi_out_fp)
          #  print(ds2)
        except FileNotFoundError:
            logging.error(f'''Error: One of both files not found at {work_dir}''')
        except Exception as e:
            logging.error(f'''An error occurred: {e}''')

        # Check if the values of slmsk are identical in two netcdf files
        slmsk1 = ds1['slmsk'].squeeze('Time')
        slmsk2 = ds2['slmsk'].squeeze('Time')
        slmsk1_val = slmsk1.values
        slmsk2_val = slmsk2.values
        nan_count = np.sum(np.isnan(slmsk2_val))
        logging.info(f''' slmsk2: {slmsk2_val.shape}: number of NaN elements: {nan_count}''')

        chk_slmsk = np.array_equal(slmsk1_val, slmsk2_val, equal_nan=True)
        if chk_slmsk:
            logging.info(f''' The values of the Sea-Land Mask (slmsk) are identical in two files.''')
        else:
            logging.warning(f''' WARNING: The values of the Sea-Land Mask (slmsk) are NOT identical in two files !!!''')
            slmsk_diff = slmsk1_val - slmsk2_val
            non_zero_count = np.count_nonzero(slmsk_diff)
            logging.info(f''' Number of non-identical elements: {non_zero_count}''')
            plot_comp_var_tile('slmsk', slmsk1_val, slmsk2_val, itp, 0, work_dir, 'msk')

        # Check the target variables and replace them with JEDI output
        for var in var_list:
            logging.info(f''' ===== Tile #: {itp}, Variable: {var} =====''')
            # Check if the variable exists in both datasets
            if var in ds1.variables and var in ds2.variables:
                # Exclude 1st dimension (Time)
                var1_3d = ds1[var].squeeze('Time')
                var2_3d = ds2[var].squeeze('Time')
              
                num_zaxis = var1_3d.shape[0]
                for iz in range(num_zaxis):
                    izp = iz+1
                    plot_comp_var_tile(var, var1_3d[iz,:,:], var2_3d[iz,:,:], itp, izp, work_dir, 'var')

            else:
                logging.error(f''' Variable "{var}" not found in one or both datasets.''')
    
            # Replace the variable values in ds1 with those from ds2 (excluding 1st dimension)
            ds1[var].values[..., :, :, :] = var2_3d

            # Plot the replaced variable
            for iz in range(num_zaxis):
                izp = iz+1
                plot_comp_var_tile(var, var2_3d[iz,:,:], ds1[var].values[0,iz,:,:], itp, izp, work_dir, 'chk')

        # Save the modified dataset to a new NetCDF file
        ds1.to_netcdf(new_sfc_data_fn)

        logging.info(f''' Variable "{var}" replaced and saved to "{new_sfc_data_fn}" successfully.''')
        ds1.close()
        ds2.close()
    

# Plot var values in two files for comparison ======================== CHJ =====
def plot_comp_var_tile(var_nm, var1, var2, tile_num, lyr_num, work_dir, opt):

    if opt == 'msk':
        out_fn = f'''plot_comp_sfc_{var_nm}_tile{tile_num}'''
        fig1_title = f'''SFC_DATA :: {var_nm} :: Tile {tile_num}'''
        fig2_title = f'''JEDI_Output :: {var_nm} :: Tile {tile_num}'''
    elif opt == 'chk':
        out_fn = f'''plot_comp_chk_{var_nm}_layer{lyr_num}_tile{tile_num}'''        
        fig1_title = f'''JEDI_Output :: {var_nm} :: Layer {lyr_num} :: Tile {tile_num}'''
        fig2_title = f'''Replaced SFC :: {var_nm} :: Layer {lyr_num} :: Tile {tile_num}'''
    else:
        out_fn = f'''plot_comp_sfc_{var_nm}_layer{lyr_num}_tile{tile_num}'''        
        fig1_title = f'''SFC_DATA :: {var_nm} :: Layer {lyr_num} :: Tile {tile_num}'''
        fig2_title = f'''JEDI_Output :: {var_nm} :: Layer {lyr_num} :: Tile {tile_num}'''

    var_all = np.concatenate((var1, var2))
    var_max = np.nanmax(var_all)
    var_min = np.nanmin(var_all)
    logging.info(f''' {opt}:: {var_nm}, Layer: {lyr_num}, Max: {var_max}, Min: {var_min}''')
 
    cs_map = 'plasma'
    cs_max = var_max
    cs_min = var_min
    tick_ln=1.5
    tick_wd=0.45
    tlb_sz=4

    fig, axs = plt.subplots(1, 2, figsize=(7,3))
    cs1 = axs[0].pcolormesh(var1, cmap=cs_map, rasterized=True, vmin=cs_min, vmax=cs_max)
    axs[0].set_title(fig1_title, fontsize=tlb_sz+1)
    axs[0].tick_params(direction='out',length=tick_ln,width=tick_wd,labelsize=tlb_sz) 
    
    cs2 = axs[1].pcolormesh(var2, cmap=cs_map, rasterized=True, vmin=cs_min, vmax=cs_max)
    axs[1].set_title(fig2_title, fontsize=tlb_sz+1)
    axs[1].tick_params(direction='out',length=tick_ln,width=tick_wd,labelsize=tlb_sz) 

    cbar = fig.colorbar(cs2, ax=axs, orientation='vertical', fraction=0.046, pad=0.04)
    cbar.set_label(var_nm, fontsize=tlb_sz+0.5)
    cbar.ax.tick_params(length=tick_ln,width=tick_wd,labelsize=tlb_sz)

    # Output figure
    ndpi = 300
    out_file(work_dir, out_fn, ndpi)


# Background plot ==================================================== CHJ =====
def back_plot(ax):
    # Resolution of background natural earth data ('50m' or '110m')
    back_res='50m'

    fline_wd=0.5  # line width
    falpha=0.7 # transparency

    # natural_earth
    land=cfeature.NaturalEarthFeature('physical','land',back_res,
                      edgecolor='face',facecolor=cfeature.COLORS['land'],
                      alpha=falpha)
    lakes=cfeature.NaturalEarthFeature('physical','lakes',back_res,
                      edgecolor='blue',facecolor='none',
                      linewidth=fline_wd,alpha=falpha)
    coastline=cfeature.NaturalEarthFeature('physical','coastline',
                      back_res,edgecolor='black',facecolor='none',
                      linewidth=fline_wd,alpha=falpha)
    states=cfeature.NaturalEarthFeature('cultural','admin_1_states_provinces',
                      back_res,edgecolor='green',facecolor='none',
                      linewidth=fline_wd,linestyle=':',alpha=falpha)
    borders=cfeature.NaturalEarthFeature('cultural','admin_0_countries',
                      back_res,edgecolor='red',facecolor='none',
                      linewidth=fline_wd,alpha=falpha)

#    ax.add_feature(land)
#    ax.add_feature(lakes)
#    ax.add_feature(states)
#    ax.add_feature(borders)
    ax.add_feature(coastline)


# Output file ======================================================= CHJ =====
def out_file(work_dir,out_file,ndpi):
    # Output figure
    fp_out=os.path.join(work_dir,out_file)
    plt.savefig(fp_out+'.png',dpi=ndpi,bbox_inches='tight')
    plt.close('all')


# Main call ========================================================= CHJ =====
if __name__=='__main__':
    main()
