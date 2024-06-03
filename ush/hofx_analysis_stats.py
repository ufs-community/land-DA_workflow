#!/usr/bin/env python3

import os
import yaml
import numpy as np
import netCDF4
import matplotlib.pyplot as plt
from scipy.stats import norm
import cartopy
import cartopy.crs as ccrs
import xarray as xr
import matplotlib.ticker

def get_obs_stats(fdir, plottype):
    global lat,lon
    omb_= []
    oma_= []    
    obs_= []
    qc_ = []
    err_= []
    lat_= []
    lon_= []
    
    for fname in os.listdir(fdir):
        print("FN:",fname)
        f= netCDF4.Dataset(fdir+'/'+fname)
#        print("NETCDF:",f)
        obs= f.groups['ObsValue'].variables['totalSnowDepth']
#        print("ObsValue:",obs)
        ombg= f.groups['ombg'].variables['totalSnowDepth']
#        print("OMBG:",ombg)
        oman= f.groups['oman'].variables['totalSnowDepth']
#        print("OMAN:",oman)
        qc= f.groups['PreQC'].variables['totalSnowDepth']
#        print("PreQC:",qc)
        obstime= f.groups['MetaData'].variables['dateTime']
#        print("OBS_TIME:",obstime)
        if plottype == 'histogram':
            ombg_= np.ma.masked_where(qc != 0, ombg)
            ombg_= np.ma.masked_where(ombg == 0, ombg_) 
            oman_= np.ma.masked_where(qc != 0, oman)
            oman_= np.ma.masked_where(ombg == 0, oman_)
            ombg= ombg_
            oman= oman_
        lat= f.groups['MetaData'].variables['latitude']
        lon= f.groups['MetaData'].variables['longitude']

        obs_.append(obs[:])
        omb_.append(ombg[:])
        oma_.append(oman[:])
        lat_.append(lat[:])
        lon_.append(lon[:])

    total_omb= np.concatenate(omb_)
    total_oma= np.concatenate(oma_)
    total_obs= np.concatenate(obs_)
    total_lat= np.concatenate(lat_)
    total_lon= np.concatenate(lon_)

    return total_oma,total_omb,total_lat,total_lon

def plot_scatter():
    field_mean= float("{:.2f}".format(np.mean(np.absolute(field))))
    field_std= float("{:.2f}".format(np.std(np.absolute(field))))

    crs= ccrs.PlateCarree()
    fig= plt.figure(figsize=(8,5))
    ax= plt.subplot(111, projection=crs)
    ax.coastlines(resolution='110m')
    colors= ['red','red','red','blue','red','blue']
    norm= plt.Normalize(yaml_data['field_range'][0],yaml_data['field_range'][1])
    sc= ax.scatter(lon, lat, c=field, s=2.0, cmap='bwr', transform=crs, norm=norm)
    cbar= plt.colorbar(sc, orientation="horizontal", shrink=0.5, pad=0.05)
    stitle= yaml_data['title_fig']+' \n '+'Mean |OMA| ='+str(field_mean)+', STDV |OMA| ='+str(field_std)
    plt.title(stitle)
    plt.savefig(yaml_data['outputfig'])
    plt.show()

def plot_histogram():
    field_mean= float("{:.2f}".format(np.mean(field)))
    field_std= float("{:.2f}".format(np.std(field)))

    nbins= yaml_data['nbins']
    xlimit= yaml_data['field_range']
    plt.hist(field[:], bins=nbins, range=xlimit, density=True, color ="blue")
    stitle= yaml_data['title_fig']+' \n '+'Mean(OMA) ='+str(field_mean)+', STDV(OMA) ='+str(field_std)
    plt.title(stitle)
    plt.savefig(yaml_data['outputfig'])
    plt.show()

if __name__ == '__main__':
    global field,yaml_data

    yaml_file= "plot_hofx.yaml"
    with open(yaml_file, 'r') as f:
        yaml_data= yaml.load(f, Loader=yaml.FullLoader)
    f.close()
    print("YAML_DATA:",yaml_data)
    oma,omb,lat,lon= get_obs_stats(yaml_data['hofx_files'],yaml_data['plottype'])
    
    if yaml_data['field_var'] == 'OMA':
        field= oma
    if yaml_data['field_var'] == 'OMB':
        field= omb    

    if yaml_data['plottype'] == 'scatter': 
        plot_scatter()
    if yaml_data['plottype'] == 'histogram':
        plot_histogram()
