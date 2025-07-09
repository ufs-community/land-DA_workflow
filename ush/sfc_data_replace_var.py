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
import xarray as xr
import numpy as np
import matplotlib.pyplot as plt


# Main part (will be called at the end) ============================= CHJ =====
def main():

    work_dir = "./"
    fn_data_base = '20250119.000000.sfc_data.tile'
    sfc_data_fn_suffix = '.nc_soil_moisture_before_inc'
    jedi_out_fn_prefix = 'jedi_smc.'
    jedi_out_fn_suffix = '.nc'
    new_sfc_data_fn_suffix = '.nc_soil_moisture_test'
    
    var_list = ["smc"]

    num_tiles = 1
    for it in range(num_tiles):
        itp = it+1
        # Input and output file name
        sfc_data_fn = fn_data_base+str(itp)+sfc_data_fn_suffix
        jedi_out_fn = jedi_out_fn_prefix+fn_data_base+str(itp)+jedi_out_fn_suffix
        new_sfc_data_fn = fn_data_base+str(itp)+new_sfc_data_fn_suffix
        # Path to input files
        sfc_data_fp = os.path.join(work_dir, sfc_data_fn)
        jedi_out_fp = os.path.join(work_dir, jedi_out_fn)
        # Open the NetCDF datasets
        try:
            ds1 = xr.open_dataset(sfc_data_fp)
            print(ds1)
            ds2 = xr.open_dataset(jedi_out_fp)
            print(ds2)
        except FileNotFoundError:
            print(f'''Error: One of both files not found at {work_dir}''')
        except Exception as e:
            print(f'''An error occurred: {e}''')

        # Check if the values of slmsk are identical in two netcdf files
        slmsk1 = ds1['slmsk'].squeeze('Time')
        slmsk2 = ds2['slmsk'].squeeze('Time')
        print(slmsk1.shape)
        print(slmsk2.shape)
        slmsk1_val = slmsk1.values
        slmsk2_val = slmsk2.values
        print(f''' slmsk, file1, max: {np.max(slmsk1_val)}, min: {np.min(slmsk1_val)}''')
        print(f''' slmsk, file2, max: {np.max(slmsk2_val)}, min: {np.min(slmsk2_val)}''')
        nan_count = np.sum(np.isnan(slmsk2_val))
        print(f''' Number of NaN elements: {nan_count}''')

        chk_slmsk = np.array_equal(slmsk1_val, slmsk2_val, equal_nan=True)
        if chk_slmsk:
            print(f''' The values of the Sea-Land Mask (slmsk) are identical in two files.''')
        else:
            print(f''' WARNING: The values of the Sea-Land Mask (slmsk) are NOT identical in two files !!!''')
            slmsk_diff = slmsk1_val - slmsk2_val
            non_zero_count = np.count_nonzero(slmsk_diff)
            print(f''' Number of non-identical elements: {non_zero_count}''')
            plot_comp_var_tile('slmsk', slmsk1_val, slmsk2_val, itp, 0, work_dir)

        # Check the target variables and replace them with JEDI output
        for var in var_list:
            print(f''' Tile #: {itp}, Variable: {var}''')
            # Check if the variable exists in both datasets
            if var in ds1.variables and var in ds2.variables:
                # Exclude 1st dimension (Time)
                var1_3d = ds1[var].squeeze('Time')
                var2_3d = ds2[var].squeeze('Time')
               
                num_zaxis = var1_3d.shape[0]
                for iz in range(num_zaxis):
                    izp = iz+1
                    print(f''' Layer (z-axis) #: {izp}''')
                    plot_comp_var_tile(var, var1_3d[iz,:,:], var2_3d[iz,:,:], itp, izp, work_dir)

            else:
                print(f''' Variable "{var}" not found in one or both datasets.''')
    
            # Replace the variable in ds1 with the variable from ds2 (only 3rd/4th dimensions)
            ds1[var].values[..., :, :] = ds2[var].values[..., :, :]

        # Save the modified dataset to a new NetCDF file
        ds1.to_netcdf(new_sfc_data_fn)

        print(f''' Variable "{var}" replaced and saved to "{new_sfc_data_fn}" successfully.''')
        ds1.close()
        ds2.close()
    

# Plot var values in two files for comparison ======================== CHJ =====
def plot_comp_var_tile(var_nm, var1, var2, tile_num, lyr_num, work_dir):

    if lyr_num == 0:
        out_fn = f'''plot_comp_sfc_{var_nm}_tile{tile_num}'''
        fig1_title = f'''SFC_DATA :: {var_nm} :: Tile {tile_num}'''
        fig2_title = f'''JEDI_Output :: {var_nm} :: Tile {tile_num}'''
    else:
        out_fn = f'''plot_comp_sfc_{var_nm}_tile{tile_num}_layer{lyr_num}'''        
        fig1_title = f'''SFC_DATA :: {var_nm} :: Layer {lyr_num} :: Tile {tile_num}'''
        fig2_title = f'''JEDI_Output :: {var_nm} :: Layer {lyr_num} :: Tile {tile_num}'''

    comb_array = np.concatenate((var1, var2))
    comb_max = np.nanmax(comb_array)
    comb_min = np.nanmin(comb_array)

    cs_map = 'plasma'
    cs_max = comb_max
    cs_min = comb_min
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
