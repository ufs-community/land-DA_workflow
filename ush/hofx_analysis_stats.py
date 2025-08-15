#!/usr/bin/env python3

import os
import logging
import yaml
import numpy as np
import netCDF4
import matplotlib.pyplot as plt
from scipy.stats import norm
import cartopy
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import xarray as xr
import matplotlib.ticker
import matplotlib as mpl
from matplotlib.colors import ListedColormap

def get_obs_stats(fname, plottype, svar_long):

    logging.info(f''' === File Name: {fname}''')
    f=netCDF4.Dataset(fname)
    logging.info(f''' NETCDF: {f}''')
    obs=f.groups['ObsValue'].variables[svar_long][:]
    logging.debug("ObsValue:",obs)
    omb=f.groups['ombg'].variables[svar_long][:]
    logging.debug("OMBG:",omb)
    lat=f.groups['MetaData'].variables['latitude'][:]
    lon=f.groups['MetaData'].variables['longitude'][:]

    numpt_omb=len(omb)
    numpt_obs=len(obs)
    logging.info(f'''Number of points (raw): {numpt_omb}, {numpt_obs}''')
    obs = [x for x, y in zip(obs, omb) if y>-5000 and y<5000]
    lat = [x for x, y in zip(lat, omb) if y>-5000 and y<5000]
    lon = [x for x, y in zip(lon, omb) if y>-5000 and y<5000]
    omb = [x for x in omb if x>-5000 and x<5000]
    numpt_omb=len(omb)
    numpt_obs=len(obs)
    logging.info(f'''Number of points (excluding zeros): {numpt_omb}, {numpt_obs}''')
    max_omb=np.max(omb)
    min_omb=np.min(omb)
    max_obs=np.max(obs)
    min_obs=np.min(obs)
    logging.info(f'''OMB max/min: {max_omb}, {min_omb}''')
    logging.info(f'''OBS max/min: {max_obs}, {min_obs}''')

    return omb,lat,lon


def plot_scatter(omb,svar,hofx_data_path,cdate,title_fig,PDY):
    logging.info(f''' ========== PLOT: SCATTER ==========''')
    
    # Set the path to Natural Earth dataset
    cartopy.config['data_dir']=yaml_data['cartopy_ne_path']

    field_mean=float("{:.2f}".format(np.mean(np.absolute(omb))))
    field_std=float("{:.2f}".format(np.std(np.absolute(omb))))
    field_max=float("{:.2f}".format(np.max(np.absolute(omb))))
    field_min=float("{:.2f}".format(np.min(np.absolute(omb))))
    logging.info(f''' Mean |OMB|= {field_mean}''')
    logging.info(f''' STDV |OMB|= {field_std}''')
    logging.info(f''' Max |OMB|= {field_max}''')
    logging.info(f''' Min |OMB|= {field_min}''')

    # Print out OMB values to file
    hofx_data_fn=f'''hofx_omb_timehis_abs_{svar}.txt'''
    hofx_data_fp=os.path.join(hofx_data_path,hofx_data_fn)
    if os.path.exists(hofx_data_fp):
        # Remove line for same date
        with open(hofx_data_fp, 'r') as f:
            lines = f.readlines()
        with open(hofx_data_fp, 'w') as f:
            for line in lines:
                columns = line.strip().split(' ')
                if columns and columns[0].strip() != cdate:
                    f.write(line)
                    
    with open(hofx_data_fp, 'a') as f:
        print(cdate,field_mean,field_std,field_max,field_min, file=f)

    crs=ccrs.PlateCarree()
    fig=plt.figure(figsize=(8,5))
    ax=plt.subplot(111, projection=crs)
    coastline=cfeature.NaturalEarthFeature('physical','coastline','50m',edgecolor='black',facecolor='none',
                      linewidth=0.5,alpha=0.7)
    ax.add_feature(coastline)
    norm=plt.Normalize(yaml_data['field_range'][0],yaml_data['field_range'][1])
    num_cmap=25
    cmap_neg=mpl.colormaps['Blues_r'].resampled(num_cmap)
    cmap_pos=mpl.colormaps['Reds'].resampled(num_cmap)
    cmap_color=np.vstack((cmap_neg(np.linspace(0.1,0.7,num_cmap)),cmap_pos(np.linspace(0.2,0.8,num_cmap))))
    cmap_new=ListedColormap(cmap_color, name='BlueRed_rw')
    sc=ax.scatter(lon, lat, c=omb, s=1.5, cmap=cmap_new, transform=crs, norm=norm)
    cbar=plt.colorbar(sc, orientation="horizontal", shrink=0.5, pad=0.05)
    stitle=title_fig+' \n '+'Mean |OMB| ='+str(field_mean)+', STDV |OMB| ='+str(field_std)
    plt.title(stitle)
    output_fn=f'''hofx_omb_{svar}_{PDY}_scatter.png'''
    plt.savefig(output_fn,dpi=200,bbox_inches='tight')
    plt.close('all')


def plot_histogram(omb,svar,hofx_data_path,cdate,title_fig,PDY):
    logging.info(f''' ========== PLOT: HISTOGRAM ==========''')    
    field_mean=float("{:.2f}".format(np.mean(omb)))
    field_std=float("{:.2f}".format(np.std(omb)))
    field_max=float("{:.2f}".format(np.max(omb)))
    field_min=float("{:.2f}".format(np.min(omb)))
    logging.info(f''' Mean OMB= {field_mean}''')
    logging.info(f''' STDV OMB= {field_std}''')
    logging.info(f''' Max OMB= {field_max}''')
    logging.info(f''' Min OMB= {field_min}''')

    # Print out OMB values to file
    hofx_data_fn=f'''hofx_omb_timehis_{svar}.txt'''
    hofx_data_fp=os.path.join(hofx_data_path,hofx_data_fn)
    if os.path.exists(hofx_data_fp):
        # Remove line for same date
        with open(hofx_data_fp, 'r') as f:
            lines = f.readlines()
        with open(hofx_data_fp, 'w') as f:
            for line in lines:
                columns = line.strip().split(' ')
                if columns and columns[0].strip() != cdate:
                    f.write(line)

    with open(hofx_data_fp, 'a') as f:
        print(cdate,field_mean,field_std,field_max,field_min, file=f)

    nbins=yaml_data['nbins']
    opt_xlimit='auto'
    if opt_xlimit=='auto':
        fld_min=int(field_min)
        fld_max=int(field_max)
        xlimit=[fld_min,fld_max]
        logging.info(f''' xlimit min= {fld_min}''')
        logging.info(f''' xlimit max= {fld_max}''')
        logging.info(f''' xlimit= {xlimit}''')
    else:
        xlimit=yaml_data['field_range']
        
    plt.hist(omb[:], bins=nbins, range=xlimit, density=True, color ="blue")
    stitle=title_fig+' \n '+'Mean(OMB) ='+str(field_mean)+', STDV(OMB) ='+str(field_std)
    plt.title(stitle)
    output_fn=f'''hofx_omb_{svar}_{PDY}_histogram.png'''
    plt.savefig(output_fn,dpi=150,bbox_inches='tight')
    plt.close('all')

if __name__ == '__main__':
    global yaml_data

    yaml_file="plot_hofx.yaml"
    with open(yaml_file, 'r') as f:
        yaml_data=yaml.load(f, Loader=yaml.FullLoader)
    f.close()

    cdate=yaml_data['cdate']
    hofx_data_path=yaml_data['hofx_data_path']
    plottype=yaml_data['plottype']
    work_dir=yaml_data['work_dir']
    OBS_GHCN_SNOW=yaml_data['OBS_GHCN_SNOW']
    OBS_IMS_SNOW=yaml_data['OBS_IMS_SNOW']
    OBS_SFCSNO=yaml_data['OBS_SFCSNO']
    OBS_SMAP=yaml_data['OBS_SMAP']
    OBS_SMOPS=yaml_data['OBS_SMOPS']
    PDY=yaml_data['PDY']
    cyc=yaml_data['cyc']
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

    for svar in svar_list:
        fn_input = f'''diag.{svar}_{PDY}{cyc}.nc'''
        logging.info(f''' Input file: {fn_input}''')
        fp_input = os.path.join(work_dir,fn_input)

        if svar == "ghcn_snow" or svar == "ims_snow" or svar == "sfcsno":
            svar_long = "totalSnowDepth"
        elif svar == "smap_soil_moisture" or svar == "smops_soil_moisture":
            svar_long = "soilMoistureVolumetric"

        omb,lat,lon=get_obs_stats(fp_input,plottype,svar_long)

        svar_upper=svar.upper()
        title_fig=f'''{svar_upper}::Obs-Bkg::{PDY}'''
        if plottype=='scatter' or plottype=='both': 
            plot_scatter(omb,svar,hofx_data_path,cdate,title_fig,PDY)
        if plottype=='histogram' or plottype=='both':
            plot_histogram(omb,svar,hofx_data_path,cdate,title_fig,PDY)
