#!/usr/bin/env python3

import os, sys
import logging
import yaml
import numpy as np
import xarray as xr
import xesmf as xe
import cartopy
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import matplotlib.pyplot as plt
import matplotlib.colors as colors
import matplotlib.ticker
import matplotlib as mpl
from matplotlib.colors import ListedColormap
from mpl_toolkits.axes_grid1 import make_axes_locatable


# === Main part (will be called at the end) ============================= CHJ =====
def main():

    yaml_file="bkg_ext_to_sfcdata.yaml"
    with open(yaml_file, 'r') as f:
        yaml_data=yaml.load(f, Loader=yaml.FullLoader)
    f.close()

    BKG_ANAL_EXT_SRC_OPT = yaml_data['BKG_ANAL_EXT_SRC_OPT']
    cartopy_ne_path = yaml_data['cartopy_ne_path']
    fn_oro_base = yaml_data['fn_oro_base']
    fn_oro_ext = yaml_data['fn_oro_ext']
    fn_sfc_base = yaml_data['fn_sfc_base']
    fn_sfc_ext = yaml_data['fn_sfc_ext']
    fn_ext_src = yaml_data['fn_ext_src']
    plot_sfc_data = yaml_data['plot_sfc_data']
    plot_src_data = yaml_data['plot_src_data']
    PY_LOG_LEVEL=yaml_data['PY_LOG_LEVEL']
    work_dir=yaml_data['work_dir']

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

    # --- Set parameters ---
    num_tiles = 6
    swvl_cs_max = 1
    swvl_cs_min = 0
    sde_cs_max = 25
    sde_cs_min = 0
    bkg_anal_ext_src_opt_upper = BKG_ANAL_EXT_SRC_OPT.upper()
    out_title_src_base = f'''Land-DA::{bkg_anal_ext_src_opt_upper}::'''
    out_fn_src_base = f'''landda_{BKG_ANAL_EXT_SRC_OPT}_src_'''
    out_title_sfc_base = f'''Land-DA::sfc_data::'''
    out_fn_sfc_base = f'''landda_{BKG_ANAL_EXT_SRC_OPT}_sfc_'''

    # --- Set the path to Natural Earth dataset ---
    cartopy.config['data_dir']=cartopy_ne_path

    # --- Read data from source data file ---
    ds1 = xr.open_dataset(fn_ext_src)  # external source data
    if BKG_ANAL_EXT_SRC_OPT == "era5land":
        lat1 = ds1["latitude"].values
        lon1 = ds1["longitude"].values       
        # --- Reshape longitude/latitude ---
        lon1_2d, lat1_2d = np.meshgrid(lon1, lat1)    
        ds1 = ds1.drop_vars(["latitude", "longitude"])
        ds1["latitude"] = (("latitude", "longitude"), lat1_2d)
        ds1["longitude"] = (("latitude", "longitude"), lon1_2d)
        # --- Extract data from source data file ---
        ds1_lat = ds1["latitude"].values
        ds1_lon = ds1["longitude"].values
        ds1_sde_o = ds1["sde"].values
        ds1_sde = np.squeeze(ds1_sde_o[0,:,:])
        ds1_swvl1_o = ds1["swvl1"].values
        ds1_swvl1 = np.squeeze(ds1_swvl1_o[0,:,:])
        ds1_swvl2_o = ds1["swvl2"].values
        ds1_swvl2 = np.squeeze(ds1_swvl2_o[0,:,:])
        ds1_swvl3_o = ds1["swvl3"].values
        ds1_swvl3 = np.squeeze(ds1_swvl3_o[0,:,:])
        ds1_swvl4_o = ds1["swvl4"].values
        ds1_swvl4 = np.squeeze(ds1_swvl4_o[0,:,:])

    elif BKG_ANAL_EXT_SRC_OPT == "gfs":
        # --- Match latitude/longitude names ---
        ds1 = ds1.rename_vars({"lat": "latitude", "lon": "longitude"})
        # --- Extract data from target data file ---
        ds1_lat = ds1["latitude"].values
        ds1_lon = ds1["longitude"].values
        ds1_sde_o = ds1["snod"].values
        ds1_sde = np.squeeze(ds1_sde_o[0,:,:])
        ds1_swvl1_o = ds1["soilw1"].values
        ds1_swvl1 = np.squeeze(ds1_swvl1_o[0,:,:])
        ds1_swvl2_o = ds1["soilw2"].values
        ds1_swvl2 = np.squeeze(ds1_swvl2_o[0,:,:])
        ds1_swvl3_o = ds1["soilw3"].values
        ds1_swvl3 = np.squeeze(ds1_swvl3_o[0,:,:])
        ds1_swvl4_o = ds1["soilw4"].values
        ds1_swvl4 = np.squeeze(ds1_swvl4_o[0,:,:])
        # --- Extract sea-land-ice mask ---
        ds1_land_o = ds1["land"].values
        ds1_land = np.squeeze(ds1_land_o[0,:,:])
        logging.info(f'''{bkg_anal_ext_src_opt_upper}::sea-land-ice  - max: {np.nanmax(ds1_land)}, min: {np.nanmax(ds1_land)}, shape: {ds1_land.shape}''')

        # --- Replace all ones for sea (land=0) and ice (land=2) with zeros ---
        ds1_swvl1[(ds1_land != 1) & (ds1_swvl1 == 1)] = 0
        ds1_swvl2[(ds1_land != 1) & (ds1_swvl2 == 1)] = 0
        ds1_swvl3[(ds1_land != 1) & (ds1_swvl3 == 1)] = 0
        ds1_swvl4[(ds1_land != 1) & (ds1_swvl4 == 1)] = 0        

    logging.info(f'''{bkg_anal_ext_src_opt_upper}::2D::latitude      - max: {np.nanmax(ds1_lat)}, min: {np.nanmin(ds1_lat)}, shape: {ds1_lat.shape}''')
    logging.info(f'''{bkg_anal_ext_src_opt_upper}::2D::longitude     - max: {np.nanmax(ds1_lon)}, min: {np.nanmin(ds1_lon)}, shape: {ds1_lon.shape}''')
    logging.info(f'''{bkg_anal_ext_src_opt_upper}::Snow Depth        - max: {np.nanmax(ds1_sde)}, min: {np.nanmin(ds1_sde)}, shape: {ds1_sde.shape}''')
    logging.info(f'''{bkg_anal_ext_src_opt_upper}::Soil Moisture (1) - max: {np.nanmax(ds1_swvl1)}, min: {np.nanmin(ds1_swvl1)}, shape: {ds1_swvl1.shape}''')
    logging.info(f'''{bkg_anal_ext_src_opt_upper}::Soil Moisture (2) - max: {np.nanmax(ds1_swvl2)}, min: {np.nanmin(ds1_swvl2)}, shape: {ds1_swvl2.shape}''')
    logging.info(f'''{bkg_anal_ext_src_opt_upper}::Soil Moisture (3) - max: {np.nanmax(ds1_swvl3)}, min: {np.nanmin(ds1_swvl3)}, shape: {ds1_swvl3.shape}''')
    logging.info(f'''{bkg_anal_ext_src_opt_upper}::Soil Moisture (4) - max: {np.nanmax(ds1_swvl4)}, min: {np.nanmin(ds1_swvl4)}, shape: {ds1_swvl4.shape}''')

    # --- Plot source data ---
    if plot_src_data == "YES":
        plot_data("sde",ds1_sde,ds1_lat,ds1_lon,out_title_src_base,out_fn_src_base,work_dir,sde_cs_max,sde_cs_min,0)
        plot_data("swvl1",ds1_swvl1,ds1_lat,ds1_lon,out_title_src_base,out_fn_src_base,work_dir,swvl_cs_max,swvl_cs_min,0)
        plot_data("swvl2",ds1_swvl2,ds1_lat,ds1_lon,out_title_src_base,out_fn_src_base,work_dir,swvl_cs_max,swvl_cs_min,0)
        plot_data("swvl3",ds1_swvl3,ds1_lat,ds1_lon,out_title_src_base,out_fn_src_base,work_dir,swvl_cs_max,swvl_cs_min,0)
        plot_data("swvl4",ds1_swvl4,ds1_lat,ds1_lon,out_title_src_base,out_fn_src_base,work_dir,swvl_cs_max,swvl_cs_min,0)
        if BKG_ANAL_EXT_SRC_OPT == "gfs":
            plot_data("land",ds1_land,ds1_lat,ds1_lon,out_title_src_base,out_fn_src_base,work_dir,2,0,0)

    # --- target data ---
    out_title_sfc_orig_base = f'''{out_title_sfc_base}Original::'''
    out_fn_sfc_orig_base = f'''{out_fn_sfc_base}orig_'''
    out_title_sfc_regrid_base = f'''{out_title_sfc_base}Regridded::'''
    out_fn_sfc_regrid_base = f'''{out_fn_sfc_base}regridded_'''

    for it in range(num_tiles):
        itp=it+1
        fn_oro=f'''{fn_oro_base}{itp}{fn_oro_ext}'''
        fn_sfc=f'''{fn_sfc_base}{itp}{fn_sfc_ext}'''

        ds2 = xr.open_dataset(fn_oro)  # target grid
        ds3 = xr.open_dataset(fn_sfc)  # target data

        # --- Match latitude/longitude names ---
        ds2 = ds2.rename_vars({"geolat": "latitude", "geolon": "longitude"})
        # --- Match coordinate names ---
        ds2 = ds2.rename({"lat": "latitude", "lon": "longitude"})

        # --- Extract data from target data file ---
        ds2_lat = ds2["latitude"].values
        ds2_lon = ds2["longitude"].values

        logging.info(f'''SFC_DATA:: Tile {itp}:: latitude  - max: {np.nanmax(ds2_lat)}, min: {np.nanmin(ds2_lat)}, shape: {ds2_lat.shape}''')
        logging.info(f'''SFC_DATA:: Tile {itp}:: longitude - max: {np.nanmax(ds2_lon)}, min: {np.nanmin(ds2_lon)}, shape: {ds2_lon.shape}''')

        ds3_snwdph_o = ds3["snwdph"].values
        ds3_snwdph = np.squeeze(ds3_snwdph_o[0,:,:])
        ds3_smc_all4 = ds3["smc"].values
        ds3_smc_all3 = np.squeeze(ds3_smc_all4[0,:,:,:])
        ds3_smc1 = np.squeeze(ds3_smc_all3[0,:,:])
        ds3_smc2 = np.squeeze(ds3_smc_all3[1,:,:])
        ds3_smc3 = np.squeeze(ds3_smc_all3[2,:,:])
        ds3_smc4 = np.squeeze(ds3_smc_all3[3,:,:])

        logging.info(f'''SFC_DATA:: Tile {itp}:: Snow Depth          - max: {np.nanmax(ds3_snwdph)}, min: {np.nanmin(ds3_snwdph)}, shape: {ds3_snwdph.shape}''')
        logging.info(f'''SFC_DATA:: Tile {itp}:: Soil Moisture (1)   - max: {np.nanmax(ds3_smc1)}, min: {np.nanmin(ds3_smc1)}, shape: {ds3_smc1.shape}''')
        logging.info(f'''SFC_DATA:: Tile {itp}:: Soil Moisture (2)   - max: {np.nanmax(ds3_smc2)}, min: {np.nanmin(ds3_smc2)}, shape: {ds3_smc2.shape}''')
        logging.info(f'''SFC_DATA:: Tile {itp}:: Soil Moisture (3)   - max: {np.nanmax(ds3_smc3)}, min: {np.nanmin(ds3_smc3)}, shape: {ds3_smc3.shape}''')
        logging.info(f'''SFC_DATA:: Tile {itp}:: Soil Moisture (4)   - max: {np.nanmax(ds3_smc4)}, min: {np.nanmin(ds3_smc4)}, shape: {ds3_smc4.shape}''')

        if plot_sfc_data == "YES":
            plot_data("snwdph",ds3_snwdph,ds2_lat,ds2_lon,out_title_sfc_orig_base,out_fn_sfc_orig_base,work_dir,sde_cs_max,sde_cs_min,itp)
            plot_data("smc1",ds3_smc1,ds2_lat,ds2_lon,out_title_sfc_orig_base,out_fn_sfc_orig_base,work_dir,swvl_cs_max,swvl_cs_min,itp)
            plot_data("smc2",ds3_smc2,ds2_lat,ds2_lon,out_title_sfc_orig_base,out_fn_sfc_orig_base,work_dir,swvl_cs_max,swvl_cs_min,itp)
            plot_data("smc3",ds3_smc3,ds2_lat,ds2_lon,out_title_sfc_orig_base,out_fn_sfc_orig_base,work_dir,swvl_cs_max,swvl_cs_min,itp)
            plot_data("smc4",ds3_smc4,ds2_lat,ds2_lon,out_title_sfc_orig_base,out_fn_sfc_orig_base,work_dir,swvl_cs_max,swvl_cs_min,itp)

        # --- Build regridder ---
        regridder = xe.Regridder(ds1, ds2, method="nearest_s2d")
    
        # --- Apply regridding ---
        ds3_smc1_new = regridder(ds1_swvl1)
        ds3_smc2_new = regridder(ds1_swvl2)
        ds3_smc3_new = regridder(ds1_swvl3)
        ds3_smc4_new = regridder(ds1_swvl4)

        logging.info(f'''Regridded SFC_DATA:: Tile {itp}:: Soil Moisture (1) - max: {np.nanmax(ds3_smc1_new)}, min: {np.nanmin(ds3_smc1_new)}, shape: {ds3_smc1_new.shape}''')
        logging.info(f'''Regridded SFC_DATA:: Tile {itp}:: Soil Moisture (2) - max: {np.nanmax(ds3_smc2_new)}, min: {np.nanmin(ds3_smc2_new)}, shape: {ds3_smc2_new.shape}''')
        logging.info(f'''Regridded SFC_DATA:: Tile {itp}:: Soil Moisture (3) - max: {np.nanmax(ds3_smc3_new)}, min: {np.nanmin(ds3_smc3_new)}, shape: {ds3_smc3_new.shape}''')
        logging.info(f'''Regridded SFC_DATA:: Tile {itp}:: Soil Moisture (4) - max: {np.nanmax(ds3_smc4_new)}, min: {np.nanmin(ds3_smc4_new)}, shape: {ds3_smc4_new.shape}''')

        if plot_sfc_data == "YES":
            plot_data("smc1",ds3_smc1_new,ds2_lat,ds2_lon,out_title_sfc_regrid_base,out_fn_sfc_regrid_base,work_dir,swvl_cs_max,swvl_cs_min,itp)
            plot_data("smc2",ds3_smc2_new,ds2_lat,ds2_lon,out_title_sfc_regrid_base,out_fn_sfc_regrid_base,work_dir,swvl_cs_max,swvl_cs_min,itp)
            plot_data("smc3",ds3_smc3_new,ds2_lat,ds2_lon,out_title_sfc_regrid_base,out_fn_sfc_regrid_base,work_dir,swvl_cs_max,swvl_cs_min,itp)
            plot_data("smc4",ds3_smc4_new,ds2_lat,ds2_lon,out_title_sfc_regrid_base,out_fn_sfc_regrid_base,work_dir,swvl_cs_max,swvl_cs_min,itp)

        smc_new_3d = np.stack([ds3_smc1_new, ds3_smc2_new, ds3_smc3_new, ds3_smc4_new], axis=0)
        logging.info(f'''New 3-D smc:: shape: {smc_new_3d.shape}''')

        smc_new_4d = np.broadcast_to(smc_new_3d, ds3_smc_all4.shape)
        logging.info(f'''New 4-D smc:: shape: {smc_new_4d.shape}''')
        logging.info(f'''New 4-D smc:: Tile {itp}:: Soil Moisture (1) - max: {np.nanmax(smc_new_4d[0,0,:,:])}, min: {np.nanmin(smc_new_4d[0,0,:,:])}''')
        logging.info(f'''New 4-D smc:: Tile {itp}:: Soil Moisture (2) - max: {np.nanmax(smc_new_4d[0,1,:,:])}, min: {np.nanmin(smc_new_4d[0,1,:,:])}''')
        logging.info(f'''New 4-D smc:: Tile {itp}:: Soil Moisture (3) - max: {np.nanmax(smc_new_4d[0,2,:,:])}, min: {np.nanmin(smc_new_4d[0,2,:,:])}''')
        logging.info(f'''New 4-D smc:: Tile {itp}:: Soil Moisture (4) - max: {np.nanmax(smc_new_4d[0,3,:,:])}, min: {np.nanmin(smc_new_4d[0,3,:,:])}''')

        # --- Replace NaN values with zeros
        logging.info(f'''SFC_DATA:: original:: No. of NaNs = {np.isnan(ds3_smc_all4).sum()}''')
        logging.info(f'''SFC_DATA:: original:: No. of zeros = {np.count_nonzero(ds3_smc_all4 == 0)}''')
        logging.info(f'''SFC_DATA:: regridded (before):: No. of NaNs = {np.isnan(smc_new_4d).sum()}''')
        logging.info(f'''SFC_DATA:: regridded (before):: No. of zeros = {np.count_nonzero(smc_new_4d == 0)}''')

        smc_new_4d_no_nan = np.nan_to_num(smc_new_4d, nan=0.0)
        ds3["smc"][:] = smc_new_4d_no_nan

        logging.info(f'''SFC_DATA:: regridded (after):: No. of NaNs = {np.isnan(ds3["smc"].values).sum()}''')
        logging.info(f'''SFC_DATA:: regridded (after):: No. of zeros = {np.count_nonzero(ds3["smc"].values == 0)}''')

        chk_smc_new = ds3["smc"].values
        logging.info(f'''Check smc:: shape: {chk_smc_new.shape}''')
        logging.info(f'''Check smc:: Tile {itp}:: Soil Moisture (1) - max: {np.nanmax(chk_smc_new[0,0,:,:])}, min: {np.nanmin(chk_smc_new[0,0,:,:])}''')
        logging.info(f'''Check smc:: Tile {itp}:: Soil Moisture (2) - max: {np.nanmax(chk_smc_new[0,1,:,:])}, min: {np.nanmin(chk_smc_new[0,1,:,:])}''')
        logging.info(f'''Check smc:: Tile {itp}:: Soil Moisture (3) - max: {np.nanmax(chk_smc_new[0,2,:,:])}, min: {np.nanmin(chk_smc_new[0,2,:,:])}''')
        logging.info(f'''Check smc:: Tile {itp}:: Soil Moisture (4) - max: {np.nanmax(chk_smc_new[0,3,:,:])}, min: {np.nanmin(chk_smc_new[0,3,:,:])}''')

        # --- Save new dataset ---
        fn_sfc_new = f'''{fn_sfc_base}{itp}_{BKG_ANAL_EXT_SRC_OPT}{fn_sfc_ext}'''
        ds3.to_netcdf(fn_sfc_new)

    

# === Plot data ========================================================== CHJ =====
def plot_data(var_nm,var_data,var_lat,var_lon,out_title_base,out_fn_base,work_dir,cs_max,cs_min,itp):

    # center of map
    c_lon = -77.0369
    cs_cmap = 'nipy_spectral_r' # good for checking NaN values
#    cs_cmap = 'gist_ncar_r'
    cbar_extend = 'neither'
    var_nm_long = var_nm

    if var_nm == "sde" or var_nm == "snwdph":
        cbar_extend = 'max'
        var_nm_long = 'snow depth'
    elif var_nm[:4] == "swvl":
        var_nm_long = f'''soil moisture ({var_nm[4]})'''
    elif var_nm[:3] == "smc":
        var_nm_long = f'''soil moisture ({var_nm[3]})'''
    elif var_nm == "land":
        var_nm_long = "sea-land-ice mask"
        cs_cmap = 'rainbow'

    print(f''' {var_nm}: cs_max= {cs_max}, cs_min= {cs_min}''')

    if itp > 0:
        out_title = f'''{out_title_base}{var_nm_long}::tile{itp}'''
        out_fn = f'''{out_fn_base}{var_nm}_tile{itp}'''
    else:
        out_title = f'''{out_title_base}{var_nm_long}'''
        out_fn = f'''{out_fn_base}{var_nm}'''

    fig,ax = plt.subplots(1,1,subplot_kw=dict(projection=ccrs.Robinson(c_lon)))
    ax.set_global()
    ax.set_title(out_title, fontsize=6)
    # Call background plot
    back_plot(ax)

    cs=ax.pcolormesh(var_lon,var_lat,var_data,cmap=cs_cmap,rasterized=True,
           vmin=cs_min,vmax=cs_max,transform=ccrs.PlateCarree())
    divider=make_axes_locatable(ax)
    ax_cb=divider.new_horizontal(size="3%",pad=0.1,axes_class=plt.Axes)
    fig.add_axes(ax_cb)
    cbar=plt.colorbar(cs,cax=ax_cb,extend=cbar_extend)
    cbar.ax.tick_params(labelsize=6)
    cbar.set_label(var_nm_long,fontsize=6)
    # Output figure
    ndpi=300
    out_file(work_dir,out_fn,ndpi)



# === Background plot ==================================================== CHJ =====
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


# === Output file ======================================================= CHJ =====
def out_file(work_dir,out_file,ndpi):
    # Output figure
    fp_out=os.path.join(work_dir,out_file)
    plt.savefig(fp_out+'.png',dpi=ndpi,bbox_inches='tight')
    plt.close('all')


# === Main call ========================================================= CHJ =====
if __name__=='__main__':
    main()
