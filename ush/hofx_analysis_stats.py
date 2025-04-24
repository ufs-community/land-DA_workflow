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

def get_obs_stats(fname, plottype, jedi_exe):

    logging.info(f''' === File Name: {fname}''')
    f=netCDF4.Dataset(fname)
    logging.info(f''' NETCDF: {f}''')
    obs=f.groups['ObsValue'].variables['totalSnowDepth'][:]
    logging.debug("ObsValue:",obs)
    omb=f.groups['ombg'].variables['totalSnowDepth'][:]
    logging.debug("OMBG:",omb)
    lat=f.groups['MetaData'].variables['latitude'][:]
    lon=f.groups['MetaData'].variables['longitude'][:]

    numpt_omb=len(omb)
    numpt_obs=len(obs)
    logging.info(f'''Number of points (raw): {numpt_omb}, {numpt_obs}''')
    obs = [x for x, y in zip(obs, omb) if y>-1000 and y<1000]
    lat = [x for x, y in zip(lat, omb) if y>-1000 and y<1000]
    lon = [x for x, y in zip(lon, omb) if y>-1000 and y<1000]
    omb = [x for x in omb if x>-1000 and x<1000]
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


def plot_scatter(hofx_data_path,cdate):
    logging.info(f''' ========== PLOT: SCATTER ==========''')
    
    # Set the path to Natural Earth dataset
    cartopy.config['data_dir']=yaml_data['cartopy_ne_path']

    field_mean=float("{:.2f}".format(np.mean(np.absolute(field))))
    field_std=float("{:.2f}".format(np.std(np.absolute(field))))
    field_max=float("{:.2f}".format(np.max(np.absolute(field))))
    field_min=float("{:.2f}".format(np.min(np.absolute(field))))
    logging.info(f''' Mean |OMB|= {field_mean}''')
    logging.info(f''' STDV |OMB|= {field_std}''')
    logging.info(f''' Max |OMB|= {field_max}''')
    logging.info(f''' Min |OMB|= {field_min}''')

    # Print out OMB values to file
    hofx_data_fp=os.path.join(hofx_data_path,"hofx_omb_timehis_abs.txt")
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
    sc=ax.scatter(lon, lat, c=field, s=1.5, cmap=cmap_new, transform=crs, norm=norm)
    cbar=plt.colorbar(sc, orientation="horizontal", shrink=0.5, pad=0.05)
    stitle=yaml_data['title_fig']+' \n '+'Mean |OMB| ='+str(field_mean)+', STDV |OMB| ='+str(field_std)
    plt.title(stitle)
    output_fn=yaml_data['output_prefix']+"_scatter.png"
    plt.savefig(output_fn,dpi=200,bbox_inches='tight')
    plt.close('all')


def plot_histogram(hofx_data_path,cdate):
    logging.info(f''' ========== PLOT: HISTOGRAM ==========''')    
    field_mean=float("{:.2f}".format(np.mean(field)))
    field_std=float("{:.2f}".format(np.std(field)))
    field_max=float("{:.2f}".format(np.max(field)))
    field_min=float("{:.2f}".format(np.min(field)))
    logging.info(f''' Mean OMB= {field_mean}''')
    logging.info(f''' STDV OMB= {field_std}''')
    logging.info(f''' Max OMB= {field_max}''')
    logging.info(f''' Min OMB= {field_min}''')

    # Print out OMB values to file
    hofx_data_fp=os.path.join(hofx_data_path,"hofx_omb_timehis.txt")
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
        
    plt.hist(field[:], bins=nbins, range=xlimit, density=True, color ="blue")
    stitle=yaml_data['title_fig']+' \n '+'Mean(OMB) ='+str(field_mean)+', STDV(OMB) ='+str(field_std)
    plt.title(stitle)
    output_fn=yaml_data['output_prefix']+"_histogram.png"
    plt.savefig(output_fn,dpi=150,bbox_inches='tight')
    plt.close('all')

if __name__ == '__main__':
    global field,yaml_data

    yaml_file="plot_hofx.yaml"
    with open(yaml_file, 'r') as f:
        yaml_data=yaml.load(f, Loader=yaml.FullLoader)
    f.close()

    hofx_data_path=yaml_data['hofx_data_path']
    cdate=yaml_data['cdate']
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

    omb,lat,lon=get_obs_stats(yaml_data['hofx_file'],yaml_data['plottype'],yaml_data['jedi_exe'])
    if yaml_data['field_var']=='OMB':
        field=omb    

    if yaml_data['plottype']=='scatter' or yaml_data['plottype']=='both': 
        plot_scatter(hofx_data_path,cdate)
    if yaml_data['plottype']=='histogram' or yaml_data['plottype']=='both':
        plot_histogram(hofx_data_path,cdate)
