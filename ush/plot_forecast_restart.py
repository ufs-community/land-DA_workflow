#!/usr/bin/env python3

###################################################################### CHJ #####
## Name		: plot_forecast_restart.py
## Usage	: Plot restart output file of land-DA workflow
## Input files  : ufs_land_restart.tile#.nc
## NOAA/EPIC
## History ===============================
## V000: 2024/09/26: Chan-Hoo Jeon : Preliminary version
## V001: 2024/10/05: Chan-Hoo Jeon : Add to land-DA workflow
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


# Main part (will be called at the end) ============================= CHJ =====
def main():
# =================================================================== CHJ =====

    global num_tiles

    yaml_file="plot_restart.yaml"
    with open(yaml_file, 'r') as f:
        yaml_data=yaml.load(f, Loader=yaml.FullLoader)
    f.close()

    path_data = yaml_data['path_data']
    work_dir = yaml_data['work_dir']
    fn_data_base = yaml_data['fn_data_base']
    fn_data_ext = yaml_data['fn_data_ext']
    soil_lvl_num = yaml_data['soil_lvl_number']
    OBS_SMAP = yaml_data['OBS_SMAP']
    OBS_SMOPS = yaml_data['OBS_SMOPS']
    out_title_base = yaml_data['out_title_base']
    out_fn_base = yaml_data['out_fn_base']
    cartopy_ne_path = yaml_data['cartopy_ne_path']
    plot_cs_cmap = yaml_data['plot_cs_cmap']   
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

    # Set the path to Natural Earth dataset
    cartopy.config['data_dir']=cartopy_ne_path

    #var_list=["snwdph","smc"]
    if OBS_SMAP == "YES" or OBS_SMOPS == "YES":
        var_list=["smc"]
    else:
        var_list=["snwdph"]
    # Number of tiles
    num_tiles=6

    # get lon, lat
    get_geo(path_data,fn_data_base,fn_data_ext)
    # plot restart file
    for var_nm in var_list:
        plot_data(path_data,fn_data_base,fn_data_ext,var_nm,soil_lvl_num,
                  out_title_base,out_fn_base,work_dir,plot_cs_cmap)
       

# geo lon/lat from orography ======================================== CHJ =====
def get_geo(path_data,fn_data_base,fn_data_ext):
# =================================================================== CHJ =====

    global glon,glat

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
        logging.info(f''' Tile{itp} ,Max= {np.max(glon_data)}''')
        logging.info(f''' Tile{itp} ,Min= {np.min(glon_data)}''')

        glat_data=np.ma.masked_invalid(data_raw.variables['grid_yt'])
        logging.info(f''' Dimension of glat(grid_yt)= {glat_data.shape}''')
        logging.info(f''' Tile{itp} ,Max= {np.max(glat_data)}''')
        logging.info(f''' Tile{itp} ,Min= {np.min(glat_data)}''')

        if itp == 1:
            ny,nx=glon_data.shape
            glon=np.zeros((num_tiles,ny,nx))
            glat=np.zeros((num_tiles,ny,nx))

        data_raw.close()        
        glon[it,:,:]=glon_data[:,:]
        glat[it,:,:]=glat_data[:,:]

    logging.info(f''' Dimension of glon= {glon.shape}''')
    logging.info(f''' Dimension of glon= {glat.shape}''')


# Get sfc_data from files and plot ================================== CHJ =====
def plot_data(path_data,fn_data_base,fn_data_ext,var_nm,soil_lvl_num,
              out_title_base,out_fn_base,work_dir,plot_cs_cmap):
# =================================================================== CHJ =====

    # center of map
    c_lon=-77.0369

    logging.info(f''' ===== data file: '{var_nm}' ========================''')
    soil_lvl_num = int(soil_lvl_num)
    # open the data file
    for it in range(num_tiles):
        itp=it+1
        fn_data=fn_data_base+str(itp)+fn_data_ext
        fp_data=os.path.join(path_data,fn_data)
        try: data_raw=nc.Dataset(fp_data)
        except: raise Exception('Could NOT find the file',fp_data)
        # Extract valid variable
        var_data=np.ma.masked_invalid(data_raw.variables[var_nm])
        if var_nm == 'stc' or var_nm == 'smc' or var_nm == 'slc':
            logging.info(f''' Dimension of original data= {var_data.shape}''')
            var_data_2d=var_data[:,soil_lvl_num-1,:,:]
        else:
            var_data_2d=var_data                
 
        logging.info(f''' Dimension of data= {var_data_2d.shape}''')
        logging.info(f''' Tile{itp}, Max= {np.max(var_data_2d)}''')
        logging.info(f''' Tile{itp}, Min= {np.min(var_data_2d)}''')

        if itp == 1:
            plt_var=var_data_2d
        else:
            plt_var=np.ma.concatenate((plt_var,var_data_2d),axis=0)
        data_raw.close()

#    plt_var=np.vstack(var_data_all)
    logging.info(f''' Dimension of data set= {plt_var.shape}''')

    cs_max=np.max(plt_var)
    cs_min=np.min(plt_var)
    logging.info(f''' cs_max= {cs_max}''')
    logging.info(f''' cs_min= {cs_min}''')

    cs_cmap=plot_cs_cmap
    cbar_extend='neither'

    # Plot each tile
    for it in range(num_tiles):
        itp=it+1
        glon_tile=np.squeeze(glon[it,:,:])
        if itp == 1:
            glon_tile=(glon_tile+180)%360-180
        glat_tile=np.squeeze(glat[it,:,:])
        var_tile=np.squeeze(plt_var[it,:,:])
        c_glon=np.round(np.mean(glon_tile),decimals=2)
        c_glat=np.round(np.mean(glat_tile),decimals=2)
        logging.info(f'''c_glon, c_glat for tile{str(it+1)}= {c_glon}, {c_glat}''')
        out_title=out_title_base+var_nm+'::Tile'+str(itp)
        out_fn=out_fn_base+var_nm+'_tile'+str(itp)

        fig,ax=plt.subplots(1,1,subplot_kw=dict(projection=ccrs.Orthographic(c_glon,c_glat)))
        ax.set_title(out_title, fontsize=6)
        # Call background plot
        back_plot(ax)
        cs=ax.pcolormesh(glon_tile,glat_tile,var_tile,cmap=cs_cmap,
            rasterized=True,vmin=cs_min,vmax=cs_max,transform=ccrs.PlateCarree())
        divider=make_axes_locatable(ax)
        ax_cb=divider.new_horizontal(size="3%",pad=0.1,axes_class=plt.Axes)
        fig.add_axes(ax_cb)
        cbar=plt.colorbar(cs,cax=ax_cb,extend='neither')
        cbar.ax.tick_params(labelsize=6)
        cbar.set_label(var_nm,fontsize=6)
        # Output figure
        ndpi=300
        out_file(work_dir,out_fn,ndpi)

    # Plot all tiles together
    out_title=f'''{out_title_base}{var_nm}::All tiles'''
    out_fn=f'''{out_fn_base}{var_nm}_alltiles'''

    fig,ax=plt.subplots(1,1,subplot_kw=dict(projection=ccrs.Robinson(c_lon)))
    ax.set_title(out_title, fontsize=6)
    # Call background plot
    back_plot(ax)
    for it in range(num_tiles):
        itp=it+1
        glon_tile=np.squeeze(glon[it,:,:])
        if itp == 1:
            glon_tile=(glon_tile+180)%360-180
        glat_tile=np.squeeze(glat[it,:,:])
        var_tile=np.squeeze(plt_var[it,:,:])
        cs=ax.pcolormesh(glon_tile,glat_tile,var_tile,cmap=cs_cmap,rasterized=True,
           vmin=cs_min,vmax=cs_max,transform=ccrs.PlateCarree())
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

