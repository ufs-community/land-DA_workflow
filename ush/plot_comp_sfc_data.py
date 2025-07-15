#!/usr/bin/env python3

###################################################################### CHJ #####
## Name		: plot_comp_sfc_data.py
## Usage	: Plot comparison of sfc_data files by analysis task
## Input files  : sfc_data.tile#.nc
## NOAA/EPIC
## History ===============================
## V000: 2024/12/10: Chan-Hoo Jeon : Preliminary version
###################################################################### CHJ #####

import os, sys
import logging
import yaml
import numpy as np
import netCDF4 as nc
import cartopy
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import xarray as xr
from scipy.stats import norm
import matplotlib.pyplot as plt
import matplotlib.colors as colors
import matplotlib.ticker
import matplotlib as mpl
from matplotlib.colors import ListedColormap
from mpl_toolkits.axes_grid1 import make_axes_locatable


# Main part (will be called at the end) ============================= CHJ =====
def main():

    global num_tiles,c_lon,work_dir,out_title_base,out_fn_base

    num_tiles=6
    # center of map
    c_lon=-77.0369

    yaml_file="plot_comp_sfc.yaml"
    with open(yaml_file, 'r') as f:
        yaml_data=yaml.load(f, Loader=yaml.FullLoader)
    f.close()

    work_dir = yaml_data['work_dir']
    fix_dir = yaml_data['fix_dir']
    fn_sfc_base = yaml_data['fn_sfc_base']
    fn_inc_base = yaml_data['fn_inc_base']
    jedi_exe = yaml_data['jedi_exe']
    jedi_type = yaml_data['jedi_type']
    orog_path = yaml_data['orog_path']
    orog_fn_base = yaml_data['orog_fn_base']
    out_title_base = yaml_data['out_title_base']
    out_fn_base = yaml_data['out_fn_base']
    PY_LOG_LEVEL = yaml_data['PY_LOG_LEVEL']
    zlvl = yaml_data['zlevel_number']
    zlvlm1 = int(zlvl)-1

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
    cartopy.config['data_dir']=os.path.join(fix_dir,"NaturalEarth")

    if jedi_type == "snow":
        sfc_var_nm="snwdph"
    elif jedi_type == "soil_moisture":
        sfc_var_nm="smc"

    # get lon, lat from orography
    slmsk=get_geo(orog_path,orog_fn_base)
    # get sfc data before analysis
    sfc1_data, sfc1_slmsk = get_sfc(work_dir,fn_sfc_base,sfc_var_nm,zlvlm1,jedi_exe,jedi_type,'before')
    # get sfc data after analysis
    sfc2_data, sfc2_slmsk = get_sfc(work_dir,fn_sfc_base,sfc_var_nm,zlvlm1,jedi_exe,jedi_type,'after')
    # get sfc increment data of analysis
    sfc_xainc_data, sfc_xainc_slmsk = get_sfc(work_dir,fn_inc_base,sfc_var_nm,zlvlm1,jedi_exe,jedi_type,'inc')
    # compare sfc1 and sfc2
    compare_sfc(sfc1_data,sfc2_data,sfc_xainc_data,sfc_var_nm,zlvlm1,jedi_type)
    # diagnosis
    diag_tool=True
    if diag_tool:
        diag_data(sfc1_data,sfc2_data,sfc_xainc_data,slmsk,sfc1_slmsk,sfc2_slmsk,sfc_xainc_slmsk,sfc_var_nm)


# diagnosis of sfc_data ============================================= CHJ =====
def diag_data(sfc1_data,sfc2_data,sfc_xainc_data,slmsk,sfc1_slmsk,sfc2_slmsk,sfc_xainc_slmsk,sfc_var_nm):

    logging.info(f' ===== Diagnosis of SFC_DATA =======================================')
    logging.info(f'''slmsk: original: {slmsk.shape} : max={np.nanmax(slmsk)} : min={np.nanmin(slmsk)}''')
    logging.info(f'''slmsk: before  : {sfc1_slmsk.shape} : max={np.nanmax(sfc1_slmsk)} : min={np.nanmin(sfc1_slmsk)}''')
    logging.info(f'''slmsk: after   : {sfc2_slmsk.shape} : max={np.nanmax(sfc2_slmsk)} : min={np.nanmin(sfc2_slmsk)}''')
    logging.info(f'''slmsk: inc     : {sfc_xainc_slmsk.shape} : max={np.nanmax(sfc_xainc_slmsk)} : min={np.nanmin(sfc_xainc_slmsk)}''')
    logging.info(f''' orog     :: 0 = non-land, 1 = land ''')
    logging.info(f''' sfc_data :: 0 = sea     , 1 = land, 2 = sea-ice ''')
    logging.info(f''' ===== Cross-check of Sea-Land masks =====''')
    comp_slmsk(slmsk,sfc1_slmsk,"orog-before")
    comp_slmsk(sfc1_slmsk,sfc2_slmsk,"before-after")


# compare sea-land masks ============================================ CHJ =====
def comp_slmsk(slmsk1,slmsk2,txt):

    # change sea-ice to sea
    slmsk1[slmsk1 == 2] = 0
    slmsk2[slmsk2 == 2] = 0
    for it in range(num_tiles):
        itp=it+1
        chk_slmsk1 = np.sum(slmsk1[it,:,:] - slmsk2[it,:,:])
        logging.info(f'''Check S-L mask :: {txt} :: Tile {itp} = {chk_slmsk1}''')


# geo lon/lat from orography ======================================== CHJ =====
def get_geo(orog_path,orog_fn_base):

    global glon,glat

    logging.info(f''' ===== geo data files ==============================================''')

    cres=orog_fn_base.split('_')[0]

    glon_all=[]
    glat_all=[]
    slmsk_all=[]
    for it in range(num_tiles):
        itp=it+1
        fn_orog=f'''{orog_fn_base}.tile{itp}.nc'''
        fp_orog=os.path.join(orog_path,fn_orog)

        try: orog=xr.open_dataset(fp_orog)
        except: raise Exception('Could NOT find the file',fp_orog)

        # Extract longitudes, and latitudes
        geolon=np.ma.masked_invalid(orog['geolon'].data)
        geolat=np.ma.masked_invalid(orog['geolat'].data)
        slmsk0=np.ma.masked_invalid(orog['slmsk'].data)
        glon_all.append(geolon[None,:])
        glat_all.append(geolat[None,:])
        slmsk_all.append(slmsk0[None,:])

        if itp==1:
            print(orog)
            print(slmsk0.shape)

    glon=np.vstack(glon_all)
    glat=np.vstack(glat_all)
    slmsk=np.vstack(slmsk_all)
    logging.debug(f''' slmsk size= {slmsk.shape}''')

    return slmsk


# Get sfc_data from files and plot ================================== CHJ =====
def get_sfc(path_sfc,fn_sfc_base,sfc_var_nm,zlvl,jedi_exe,jedi_type,sfc_opt):

    logging.info(f''' ===== sfc files: {sfc_var_nm} :: {sfc_opt} ===============================''')
    sfc_data_all=[]
    sfc_slmsk_all=[]
    if sfc_opt == 'before':
        fn_sfc_ext=f'''.nc_{jedi_type}_before_inc'''
    elif sfc_opt == 'after':
        fn_sfc_ext=f'''.nc_{jedi_type}_after_inc'''
    else:
        fn_sfc_ext=".nc"

    for it in range(num_tiles):
        itp=it+1
        fn_sfc=f'''{fn_sfc_base}{itp}{fn_sfc_ext}'''
        fp_sfc=os.path.join(path_sfc,fn_sfc)

        try: sfc=xr.open_dataset(fp_sfc)
        except: raise Exception('Could NOT find the file',fp_sfc)

        # Extract variable
        sfc_data=np.ma.masked_invalid(sfc[sfc_var_nm].data)
        if jedi_exe == '3dvar' and sfc_opt == 'inc':
            slmsk_data=np.zeros(sfc_data.shape)
            if itp == 1:
                logging.warning(f'''!!! S-L mask is not available in inc files for 3D-VAR: set to zeros !!!''')
        else:
          slmsk_data=np.ma.masked_invalid(sfc['slmsk'].data)

        if itp == 1:
            print(sfc)
            logging.debug(f''' sfc_data size= {sfc_data.shape}''')
            logging.debug(f''' slmsk size= {slmsk_data.shape}''')

        slmsk_data2d=np.squeeze(slmsk_data,axis=0)
        if sfc_var_nm == 'stc' or sfc_var_nm == 'smc' or sfc_var_nm == 'slc':
            sfc_data3d=np.squeeze(sfc_data,axis=0)
            sfc_data2d=sfc_data3d[zlvl,:,:]
        else:
            sfc_data2d=np.squeeze(sfc_data,axis=0)

        sfc_data_all.append(sfc_data2d[None,:])
        sfc_slmsk_all.append(slmsk_data2d[None,:])

    sfc_var=np.vstack(sfc_data_all)
    sfc_slmsk=np.vstack(sfc_slmsk_all)

    if sfc_opt == 'inc':
        plot_increment(sfc_var,sfc_var_nm,sfc_opt,zlvl,jedi_type)
    else:
        plot_data(sfc_var,sfc_var_nm,sfc_opt,zlvl,jedi_type)
   
    return sfc_var, sfc_slmsk


# Compare two data set and plot ===================================== CHJ =====
def compare_sfc(sfc_data1,sfc_data2,inc_data,sfc_var_nm,zlvl,jedi_type):

    logging.info(f''' ===== compare files ===============================================''')
    logging.info(f''' data 1= {sfc_data1.shape}''')
    logging.info(f''' data 2= {sfc_data2.shape}''')

    diff_data=sfc_data2-sfc_data1
    logging.info(f''' diff. data= {diff_data.shape}''')
    plot_increment(diff_data,sfc_var_nm,'diff_sfc',zlvl,jedi_type)


# increment/difference plot ========================================== CHJ =====
def plot_increment(plt_var,plt_var_nm,plt_out_txt,zlvl,jedi_type):

    var_max=np.nanmax(plt_var)
    var_min=np.nanmin(plt_var)
    logging.info(f''' {plt_var_nm}: diff : var_max= {var_max}''')
    logging.info(f''' {plt_var_nm}: diff : var_min= {var_min}''')

    if var_max == var_min:
        cs_max = max(abs(var_max),abs(var_min))+0.1
        cs_min = cs_max*-1.0
    else:
        cs_max = max(abs(var_max),abs(var_min))
        cs_min = cs_max*-1.0

    cs_cmap='seismic'
    nm_svar='\u0394'+plt_var_nm
    n_rnd=0
    cbar_extend='neither'

    if jedi_type == 'soil_moisture':
        out_title=f'''{out_title_base}{plt_var_nm}::L{zlvl+1}::{plt_out_txt}'''
        out_fn=f'''{out_fn_base}{plt_var_nm}_z{zlvl+1}_{plt_out_txt}'''
    else:
        out_title=f'''{out_title_base}{plt_var_nm}::{plt_out_txt}'''
        out_fn=f'''{out_fn_base}{plt_var_nm}_{plt_out_txt}'''

    fig,ax=plt.subplots(1,1,subplot_kw=dict(projection=ccrs.Robinson(c_lon)))
    ax.set_title(out_title, fontsize=6)
    # Call background plot
    back_plot(ax)

    for it in range(num_tiles):
        cs=ax.pcolormesh(glon[it,:,:],glat[it,:,:],plt_var[it,:,:],cmap=cs_cmap,rasterized=True,
            vmin=cs_min,vmax=cs_max,transform=ccrs.PlateCarree())

    divider=make_axes_locatable(ax)
    ax_cb=divider.new_horizontal(size="3%",pad=0.1,axes_class=plt.Axes)
    fig.add_axes(ax_cb)
    cbar=plt.colorbar(cs,cax=ax_cb,extend=cbar_extend)
    cbar.ax.tick_params(labelsize=6)
    cbar.set_label(nm_svar,fontsize=6)
    # Output figure
    ndpi=300
    out_file(work_dir,out_fn,ndpi)


# data plot ========================================================== CHJ =====
def plot_data(plt_var,plt_var_nm,plt_out_txt,zlvl,jedi_type):

    var_max=np.nanmax(plt_var)
    var_min=np.nanmin(plt_var)
    logging.info(f''' var_max= {var_max}''')
    logging.info(f''' var_min= {var_min}''')
    var_max05=var_max*0.5
    var_min05=var_min*0.5
    logging.info(f''' var_max05= {var_max05}''')
    logging.info(f''' var_min05= {var_min05}''')

    cmap_range_opt='real'
    cs_cmap='gist_ncar_r'
    if cmap_range_opt=='symmetry':
        n_rnd=0
        tmp_cmp=max(abs(var_max05),abs(var_min05))
        cs_min=round(-tmp_cmp,n_rnd)
        cs_max=round(tmp_cmp,n_rnd)
        cbar_extend='both'
    elif cmap_range_opt=='round':
        n_rnd=0
        cs_min=round(var_min05,n_rnd)
        cs_max=round(var_max05,n_rnd)
        cbar_extend='both'
    elif cmap_range_opt=='real':
        cs_min=var_min
        cs_max=var_max
        cbar_extend='neither'
    elif cmap_range_opt=='fixed':
        cs_min=0.0
        cs_max=150.0
        cbar_extend='both'
    else:
        sys.exit('ERROR: wrong colormap-range flag !!!')

    logging.info(f''' cs_max= {cs_max}''')
    logging.info(f''' cs_min= {cs_min}''')

    if jedi_type == 'soil_moisture':
        out_title=f'''{out_title_base}{plt_var_nm}::L{zlvl+1}::{plt_out_txt}'''
        out_fn=f'''{out_fn_base}{plt_var_nm}_z{zlvl+1}_{plt_out_txt}'''
    else:
        out_title=f'''{out_title_base}{plt_var_nm}::{plt_out_txt}'''
        out_fn=f'''{out_fn_base}{plt_var_nm}_{plt_out_txt}'''

    fig,ax=plt.subplots(1,1,subplot_kw=dict(projection=ccrs.Robinson(c_lon)))
    ax.set_title(out_title, fontsize=6)
    # Call background plot
    back_plot(ax)

    for it in range(num_tiles):
        cs=ax.pcolormesh(glon[it,:,:],glat[it,:,:],plt_var[it,:,:],cmap=cs_cmap,rasterized=True,
            vmin=cs_min,vmax=cs_max,transform=ccrs.PlateCarree())

    divider=make_axes_locatable(ax)
    ax_cb=divider.new_horizontal(size="3%",pad=0.1,axes_class=plt.Axes)
    fig.add_axes(ax_cb)
    cbar=plt.colorbar(cs,cax=ax_cb,extend=cbar_extend)
    cbar.ax.tick_params(labelsize=6)
    cbar.set_label(plt_var_nm,fontsize=6)
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

