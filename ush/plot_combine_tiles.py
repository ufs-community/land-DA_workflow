#!/usr/bin/env python3

###################################################################### CHJ #####
## Name		: plot_combine_tiles.py
## Usage	: Combine and plot six tiles of land-DA workflow
## Input files  : ufs_land_restart.tile#.nc
## NOAA/EPIC
## History ===============================
## V000: 2025/02/23: Chan-Hoo Jeon : Preliminary version
###################################################################### CHJ #####

import os, sys
import logging
import yaml
import numpy as np
import netCDF4 as nc
import cartopy
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import matplotlib.pyplot as plt
import matplotlib.colors as colors
import matplotlib.ticker
import matplotlib as mpl
from matplotlib.colors import ListedColormap
from mpl_toolkits.axes_grid1 import make_axes_locatable
from scipy.interpolate import griddata


# Main part (will be called at the end) ============================= CHJ =====
def main():
# =================================================================== CHJ =====

    global num_tiles

    yaml_file="plot_combine_tiles.yaml"
    with open(yaml_file, 'r') as f:
        yaml_data=yaml.load(f, Loader=yaml.FullLoader)
    f.close()

    path_data=yaml_data['path_data']
    work_dir=yaml_data['work_dir']
    fn_data_base=yaml_data['fn_data_base']
    fn_data_ext=yaml_data['fn_data_ext']
    soil_lvl_num=yaml_data['soil_lvl_number']
    out_title_base=yaml_data['out_title_base']
    out_fn_base=yaml_data['out_fn_base']
    cartopy_ne_path=yaml_data['cartopy_ne_path']
    nlon_plot=yaml_data['nlon_plot']
    nlat_plot=yaml_data['nlat_plot']
    nlon_plot=int(nlon_plot)
    nlat_plot=int(nlat_plot)
    griddata_method=yaml_data['griddata_method']
    shading_option=yaml_data['shading_option']
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
    
    # Set the path to Natural Earth dataset
    cartopy.config['data_dir']=cartopy_ne_path

    #var_list=["snwdph","smc"]
    var_list=["snwdph"]
    # Number of tiles
    num_tiles=6

    # get lon, lat
    glon, glat = get_geo(path_data,fn_data_base,fn_data_ext)
    # plot restart file
    for var_nm in var_list:
        sfc_data = get_data(path_data,fn_data_base,fn_data_ext,var_nm,soil_lvl_num)
        plot_data(glon,glat,sfc_data,var_nm,out_title_base,out_fn_base,work_dir,
                  nlon_plot,nlat_plot,griddata_method,shading_option)
       

# geo lon/lat from orography ======================================== CHJ =====
def get_geo(path_data,fn_data_base,fn_data_ext):
# =================================================================== CHJ =====

    logging.info(f''' ===== geo data files ====================================''')
    # open the data file
    for it in range(num_tiles):
        itp=it+1
        fn_data=fn_data_base+str(itp)+fn_data_ext
        fp_data=os.path.join(path_data,fn_data)
        try: data_raw=nc.Dataset(fp_data)
        except: raise Exception('Could NOT find the file',fp_data)
        if itp == 1:
            print(data_raw)
        # Extract geo data
        glon_data=np.ma.masked_invalid(data_raw.variables['grid_xt'])
        logging.info(f''' Dimension of glon(grid_xt)= {glon_data.shape}''')
        logging.info(f''' Tile{itp}, Max= {np.max(glon_data)}''')
        logging.info(f''' Tile{itp}, Min= {np.min(glon_data)}''')

        glat_data=np.ma.masked_invalid(data_raw.variables['grid_yt'])
        logging.info(f''' Dimension of glat(grid_yt)= {glat_data.shape}''')
        logging.info(f''' Tile{itp}, Max= {np.max(glat_data)}''')
        logging.info(f''' Tile{itp}, Min= {np.min(glat_data)}''')

        if itp == 1:
            glon = glon_data
            glat = glat_data
        else:
            glon = np.ma.concatenate((glon,glon_data),axis=1)
            glat = np.ma.concatenate((glat,glat_data),axis=1)
        data_raw.close()
        logging.info(f''' Dimension of glon= {glon.shape}''')
        logging.info(f''' Dimension of glon= {glat.shape}''')

    glon_1d = glon.flatten()
    glat_1d = glat.flatten()        
    logging.info(f''' Dimension of glon_1d= {glon_1d.shape}''')
    logging.info(f''' Dimension of glon_1d= {glat_1d.shape}''')

    return glon_1d, glat_1d


# Get sfc_data from files =========================================== CHJ =====
def get_data(path_data,fn_data_base,fn_data_ext,var_nm,soil_lvl_num):
# =================================================================== CHJ =====

    logging.info(f''' ===== data file: '{var_nm}' ========================''')
    # open the data file
    for it in range(num_tiles):
        itp=it+1
        fn_data=fn_data_base+str(itp)+fn_data_ext
        fp_data=os.path.join(path_data,fn_data)
        try: data_raw=nc.Dataset(fp_data)
        except: raise Exception('Could NOT find the file',fp_data)
        #if itp == 1:
        #    print(data_raw)
        # Extract valid variable
        var_data=np.ma.masked_invalid(data_raw.variables[var_nm])

        if var_nm == 'stc' or var_nm == 'smc' or var_nm == 'slc':
            logging.info(f''' Dimension of original data= {var_data.shape}''')
            var_data3d=np.squeeze(var_data,axis=0)
            var_data2d_tmp=var_data3d[soil_lvl_num-1,:,:]
            var_data2d=np.squeeze(var_data2d_tmp,axis=0)
        else:
            logging.info(f''' Dimension of original data= {var_data.shape}''')
            var_data2d=np.squeeze(var_data,axis=0)

        logging.info(f''' Dimension of data= {var_data2d.shape}''')
        logging.info(f''' Tile{itp}, Max= {np.max(var_data2d)}''')
        logging.info(f''' Tile{itp}, Min= {np.min(var_data2d)}''')

        if itp == 1:
            sfc_data = var_data2d
        else:
            sfc_data = np.ma.concatenate((sfc_data,var_data2d),axis=1)
        data_raw.close()
        logging.info(f''' Dimension of sfc_data= {sfc_data.shape}''')

    sfc_data_1d = sfc_data.flatten()
    logging.info(f'''Dimension of sfc_data_1d= {sfc_data_1d.shape}''')

    return sfc_data_1d


# Plot data ========================================================= CHJ =====
def plot_data(glon,glat,sfc_data,var_nm,out_title_base,out_fn_base,work_dir,
              nlon_plot,nlat_plot,griddata_method,shading_option):
# =================================================================== CHJ =====

    logging.info(f''' ===== Plotting data ================================''')

    # Find fill value
    sfc_fill_value = sfc_data.fill_value
    logging.info(f''' Fill value: {sfc_fill_value}''')

    # Define and interpolate the grid/data for mesh plot
    num_glon_mesh=nlon_plot
    num_glat_mesh=nlat_plot
    lon_min=np.min(glon)
    lon_max=np.max(glon)
    lat_min=round(np.min(glat))
    lat_max=round(np.max(glat))
    logging.debug(f''' glon size= {glon.shape}''')
    logging.debug(f''' glat size= {glat.shape}''')
    logging.debug(f''' data size= {sfc_data.shape}''')
    glon_mi=np.linspace(lon_min,lon_max,num_glon_mesh)
    glat_mi=np.linspace(lat_min,lat_max,num_glat_mesh)
    glon_m, glat_m = np.meshgrid(glon_mi,glat_mi)
    logging.info(f''' Max glon mesh= {np.max(glon_m)}''')
    logging.info(f''' Min glon mesh= {np.min(glon_m)}''')
    logging.info(f''' Max glat mesh= {np.max(glat_m)}''')
    logging.info(f''' Min glat mesh= {np.min(glat_m)}''')
    logging.debug(f''' glon_m size= {glon_m.shape}''')
    logging.debug(f''' glat_m size= {glat_m.shape}''')
    sfc_data_m = griddata((glon,glat),sfc_data,(glon_m,glat_m),method=griddata_method,fill_value=sfc_fill_value)
    sfc_data_m_masked = np.ma.masked_where(sfc_data_m == sfc_fill_value, sfc_data_m)
    logging.debug(f''' data_m size= {sfc_data_m_masked.shape}''')

    cs_max=np.max(sfc_data_m_masked)
    cs_min=np.min(sfc_data_m_masked)
    logging.info(f'''data_cs_max= {cs_max}''')
    logging.info(f'''data_cs_min= {cs_min}''')

    # center of map
    c_lon=-77.0369

    cs_cmap='gist_ncar_r'
    cbar_extend='neither'

    out_title=f'''{out_title_base}{var_nm}'''
    out_fn=f'''{out_fn_base}{var_nm}'''

    fig,ax=plt.subplots(1,1,subplot_kw=dict(projection=ccrs.Robinson(c_lon)))
    ax.set_title(out_title, fontsize=6)
    # Call background plot
    back_plot(ax)

    cs=ax.pcolormesh(glon_m,glat_m,sfc_data_m_masked,cmap=cs_cmap,rasterized=True,
       shading=shading_option,vmin=cs_min,vmax=cs_max,transform=ccrs.PlateCarree())

    divider=make_axes_locatable(ax)
    ax_cb=divider.new_horizontal(size="3%",pad=0.1,axes_class=plt.Axes)
    fig.add_axes(ax_cb)
    cbar=plt.colorbar(cs,cax=ax_cb,extend=cbar_extend)
    cbar.ax.tick_params(labelsize=6)
    cbar.set_label(var_nm,fontsize=6)
   
    # Output figure
    ndpi=300
    out_file(work_dir,out_fn,ndpi)


# Background plot ==================================================== CHJ =====
def back_plot(ax):
# ==================================================================== CHJ =====

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
# =================================================================== CHJ =====
    # Output figure
    fp_out=os.path.join(work_dir,out_file)
    plt.savefig(fp_out+'.png',dpi=ndpi,bbox_inches='tight')
    plt.close('all')


# Main call ========================================================= CHJ =====
if __name__=='__main__':
    main()

