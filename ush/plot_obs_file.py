#!/usr/bin/env python3

###################################################################### CHJ #####
## Name		  : plot_obs_file.py
## Usage	  : Plot observation data file of land-DA workflow
## NOAA/EPIC
## History ===============================
## V000: 2024/12/03: Chan-Hoo Jeon : Preliminary version
## V001: 2025/04/17: Chan-Hoo Jeon : Add IMS option
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
from mpl_toolkits.axes_grid1 import make_axes_locatable


# Main part (will be called at the end) ============================= CHJ =====
def main():

    yaml_file="plot_obs_file.yaml"
    with open(yaml_file, 'r') as f:
        yaml_data=yaml.load(f, Loader=yaml.FullLoader)
    f.close()

    work_dir=yaml_data['work_dir']
    cartopy_ne_path=yaml_data['cartopy_ne_path']
    fn_input_ghcn=yaml_data['fn_input_ghcn']
    fn_input_ims=yaml_data['fn_input_ims']
    fn_input_smap=yaml_data['fn_input_smap']
    fn_input_smops=yaml_data['fn_input_smops']
    OBS_GHCN_SNOW=yaml_data['OBS_GHCN_SNOW']
    OBS_IMS_SNOW=yaml_data['OBS_IMS_SNOW']
    OBS_SMAP=yaml_data['OBS_SMAP']
    OBS_SMOPS=yaml_data['OBS_SMOPS']
    PDY=yaml_data['PDY']
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

    # Plot GHCN
    if OBS_GHCN_SNOW == "YES":
       obs_plot("ghcn",PDY,work_dir,fn_input_ghcn)
    # Plot IMS
    if OBS_IMS_SNOW == "YES":
       obs_plot("ims",PDY,work_dir,fn_input_ims)
    # Plot SMAP
    if OBS_SMAP == "YES":
       obs_plot("smap",PDY,work_dir,fn_input_smap)
    # Plot SMOPS
    if OBS_SMOPS == "YES":
       obs_plot("smops",PDY,work_dir,fn_input_smops)


# obs plot =============================================== CHJ =====
def obs_plot(obs_type,PDY,work_dir,fn_input):

    logging.info(f''' ===== INPUT:: {obs_type}:: '{fn_input}' ================================''')

    # open the data file
    fpath=os.path.join(work_dir,fn_input)
    try: mdat=nc.Dataset(fpath)
    except: raise Exception('Could NOT find the file',fpath)

    logging.debug(" MetaData:", mdat.groups['MetaData'])
    logging.debug(" ObsValue:", mdat.groups['ObsValue'])

    lon = mdat.groups['MetaData'].variables['longitude'][:]
    lat = mdat.groups['MetaData'].variables['latitude'][:]
    # Variables
    #vars_out=["ObsValue", "ObsError", "PreQC"]
    vars_out=["ObsValue"]

    # Highest and lowest longitudes and latitudes for plot extent
    lon_min=np.min(lon)
    lon_max=np.max(lon)
    lat_min=np.min(lat)
    lat_max=np.max(lat)
    logging.info(f''' lon min,max = {lon_min}, {lon_max}''')
    logging.info(f''' lat min,max = {lat_min}, {lat_max}''')

    #extent=[lon_min,lon_max,lat_min,lat_max]
    extent=[]
    if obs_type != "smap":
        # for Northern Hemisphere
        extent=[-179,179,0,82.5]
        # for CONUS
        #extent=[-125,-66,23,53]
        logging.info(f''' Map extent= {extent}''')

    #c_lon=np.mean(extent[:2])
    c_lon=-77.0369 # D.C.
    logging.info(f''' c_lon= {c_lon}''')

    for svar in vars_out:
        svar_plot(svar,mdat,lon,lat,c_lon,extent,obs_type,PDY,work_dir)
    

# Variable plot =============================================== CHJ =====
def svar_plot(svar,mdat,lon,lat,c_lon,extent,obs_type,PDY,work_dir):

    logging.info(' ===== '+svar+' ==========================================')

    cs_cmap='gist_ncar_r'
    lb_ext='neither'
    tick_ln=1.5
    tick_wd=0.45
    tlb_sz=3
    n_rnd=2
    cmap_range='fixed'
    scat_sz=1.0

    # Extract data array
    if obs_type == "smap" or obs_type == "smops":
        gvar="soilMoistureVolumetric"
        pvar="SoilMoisture"
    else:
        gvar="totalSnowDepth"
        pvar="SnowDepth"

    sfld=mdat.groups[svar].variables[gvar][:]

    obs_type_upper=obs_type.upper()
    out_title_fld=f'''Land-DA::Obs::{obs_type_upper}::{PDY}::{pvar}'''
    out_fn=f'''landda_obs_{obs_type}_{PDY}_{pvar}'''

    # Check array size
    lon_len = len(lon)
    lat_len = len(lat)
    sfld_len = len(sfld)
    logging.info(f''' length of lon = {lon_len}''')
    logging.info(f''' length of lat = {lat_len}''')
    logging.info(f''' lenght of sfld = {sfld_len}''')
    if lon_len != lat_len or lon_len != sfld_len or lat_len != sfld_len:
        sys.exit('ERROR: array size mismatched !!!')

    # Max and Min of the field
    fmax=np.max(sfld)
    fmin=np.min(sfld)
    logging.info(f''' Max of {pvar}= {fmax}''')
    logging.info(f''' Min of {pvar}= {fmin}''')

    # Make the colormap range symmetry
    logging.info(f''' cmap range= {cmap_range}''')
    if cmap_range=='symmetry':
        tmp_cmp=max(abs(fmax),abs(fmin))
        cs_min=round(-tmp_cmp,n_rnd)
        cs_max=round(tmp_cmp,n_rnd)
    elif cmap_range=='round':
        cs_min=round(fmin,n_rnd)
        cs_max=round(fmax,n_rnd)
    elif cmap_range=='real':
        cs_min=fmin
        cs_max=fmax
    elif cmap_range=='fixed':
        cs_min=0
        if obs_type == 'ims':
            cs_max=100.0
        elif obs_type == 'ghcn':
            cs_max=1000.0
        elif obs_type == 'smap' or obs_type == 'smops':
            cs_max=1.0
            cs_min=0.0
        else:
            cs_max=300.0
    else:
        sys.exit('ERROR: wrong colormap-range flag !!!')

    logging.info(f''' cs_max= {cs_max}''')
    logging.info(f''' cs_min= {cs_min}''')

    # Plot field
    fig,ax=plt.subplots(1,1,subplot_kw=dict(projection=ccrs.Robinson(c_lon)))
    if obs_type == "smap" or obs_type == "smops":
        ax.set_global()
    else:
        ax.set_extent(extent, ccrs.PlateCarree())
    # Call background plot
    back_plot(ax)
    ax.set_title(out_title_fld,fontsize=8)
    cs=ax.scatter(lon,lat,transform=ccrs.PlateCarree(),c=sfld,cmap=cs_cmap,
                  vmin=cs_min,vmax=cs_max,s=scat_sz)
    divider=make_axes_locatable(ax)
    ax_cb=divider.new_horizontal(size="3%",pad=0.1,axes_class=plt.Axes)
    fig.add_axes(ax_cb)
    cbar=plt.colorbar(cs,cax=ax_cb,extend=lb_ext)
    cbar.ax.tick_params(labelsize=7)
    cbar.set_label(pvar,fontsize=7)

    # Output figure
    ndpi=300
    out_file(work_dir,out_fn,ndpi)


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

