#!/usr/bin/env python3

import netCDF4
from netCDF4 import Dataset
import numpy as np
import os
import argparse
import logging
from datetime import datetime, timedelta

# =================================================================== CHJ =====
def create_netcdf_from_files(file1_path, file2_path, output_path):
    """
    Opens two NetCDF files, extracts specified variables, and saves them to a new NetCDF file.
    """

    # Open the NetCDF files
    dataset_1 = Dataset(file1_path, 'r')
    dataset_2 = Dataset(file2_path, 'r')

    logging.debug(f''' FILE 1: {dataset_1}''')
    logging.debug(f''' FILE 2: {dataset_2}''')    

    # Extract dimensions
    latitude = dataset_1.dimensions['latitude']
    longitude = dataset_1.dimensions['longitude']
    time = dataset_1.dimensions['valid_time']
    # Convert time from seconds to hours
    time_var_orig = dataset_1.variables['valid_time']
    time_units_orig = time_var_orig.units
    logging.info(f''' TIME units (original): {time_units_orig}''')
    logging.debug(f''' TIME (original): {time_var_orig[:]}''')
    dates = netCDF4.num2date(time_var_orig[:], time_units_orig)
    time_var_new = [(date - datetime(1900,1,1)).total_seconds() / 3600 for date in dates]
    time_units_new = 'hours since 1900-01-01'
    logging.info(f''' TIME units (new): {time_units_new}''')
    logging.debug(f''' TIME (new): {time_var_new}''')

    # Extract variables from File 1
    precipitation = dataset_1.variables['avg_tprate'][:]
    downward_longwave = dataset_1.variables['avg_sdlwrf'][:]
    downward_solar = dataset_1.variables['avg_sdswrf'][:]

    # Extract variables from File 2
    u10 = dataset_2.variables['u10'][:]
    v10 = dataset_2.variables['v10'][:]
    wind_speed = np.sqrt(u10**2 + v10**2)
    logging.info(f''' wind_speed is calculated.''')
    temperature = dataset_2.variables['t2m'][:]
    surface_pressure = dataset_2.variables['sp'][:]
    sp_hpa = surface_pressure * 0.01
    d2m = dataset_2.variables['d2m'][:]
    specific_humidity = 0.622 * 6.113 / sp_hpa * np.exp(5420 * (d2m - 273.15)/(d2m * 273.15))
    specific_humidity_units = 'kg kg**-1'
    logging.info(f''' specific_humidity is calculated.''')

    # Create a new NetCDF file
    dataset_new = Dataset(output_path, 'w', format='NETCDF4')
    
    # Create dimensions in the new file
    dataset_new.createDimension('latitude', len(latitude))
    dataset_new.createDimension('longitude', len(longitude))
    dataset_new.createDimension('time', len(time))
    
    # Create variables in the new file
    lat_var = dataset_new.createVariable('latitude', 'f8', ('latitude',))
    lon_var = dataset_new.createVariable('longitude', 'f8', ('longitude',))
    time_var = dataset_new.createVariable('time', 'f8', ('time',))
    t2m_var = dataset_new.createVariable('temperature', np.float32, ('time', 'latitude', 'longitude'), fill_value=9.999e20)
    sp_var = dataset_new.createVariable('surface_pressure', np.float32, ('time', 'latitude', 'longitude'), fill_value=9.999e20)
    tprate_var = dataset_new.createVariable('precipitation', np.float32, ('time', 'latitude', 'longitude'), fill_value=9.96921e36)
    sdlwrf_var = dataset_new.createVariable('downward_longwave', np.float32, ('time', 'latitude', 'longitude'), fill_value=9.96921e36)
    sdswrf_var = dataset_new.createVariable('downward_solar', np.float32, ('time', 'latitude', 'longitude'), fill_value=9.96921e36)
    wp_var = dataset_new.createVariable('wind_speed', np.float32, ('time', 'latitude', 'longitude'), fill_value=9.96921e36)
    shum_var = dataset_new.createVariable('specific_humidity', np.float32, ('time', 'latitude', 'longitude'), fill_value=9.96921e36)

    # Write data to the new file
    lat_var[:] = dataset_1.variables['latitude'][:]
    lon_var[:] = dataset_1.variables['longitude'][:]
    time_var[:] = time_var_new
    t2m_var[:] = temperature
    sp_var[:] = surface_pressure
    tprate_var[:] = precipitation
    sdlwrf_var[:] = downward_longwave
    sdswrf_var[:] = downward_solar
    wp_var[:] = wind_speed
    shum_var[:] = specific_humidity
    
    # Add attributes
    lat_var.standard_name = 'latitude'
    lat_var.long_name = 'latitude'
    lat_var.units = dataset_1.variables['latitude'].units
    lat_var.axis = 'Y'
    lon_var.standard_name = 'longitude'
    lat_var.long_name = 'longitude'
    lon_var.units = dataset_1.variables['longitude'].units
    lon_var.axis = 'X'
    time_var.standard_name = 'time'
    time_var.units = time_units_new
    time_var.calendar = 'standard'
    time_var.axis = 'T'
    sdlwrf_var.units = dataset_1.variables['avg_sdlwrf'].units
    sdswrf_var.units = dataset_1.variables['avg_sdswrf'].units
    tprate_var.units = dataset_1.variables['avg_tprate'].units
    t2m_var.units = dataset_2.variables['t2m'].units
    sp_var.units = dataset_2.variables['sp'].units
    wp_var.units = dataset_2.variables['u10'].units
    shum_var.units = specific_humidity_units    

    # Close the datasets
    dataset_1.close()
    dataset_2.close()
    dataset_new.close()

    logging.info(f''' ERA5 forcing file has been created successfully !!!''')


# =================================================================== CHJ =====
def parse_args(argv):
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Create JEDI configuration YAML file.")
    parser.add_argument(
            "-i",
            "--input_dir_path",
            dest="input_dir_path",
            required=True,
            help="Input directory path.",
            )
    parser.add_argument(
            "-c",
            "--cdate",
            dest="yyyymmdd",
            required=True,
            help="current date (YYYYMMDD).",
            )
    parser.add_argument(
            "-l",
            "--loglevel",
            dest="PY_LOG_LEVEL",
            default="INFO",
            help="Python logging option only for this script.",
            )
    return parser.parse_args(argv)

 
# =================================================================== CHJ =====
if __name__ == '__main__':
    args = parse_args(sys.argv[1:])
    log_level_str = args.PY_LOG_LEVEL.upper()
    try:
        log_level = getattr(logging, log_level_str)
    except AttributeError:
        log_level_str = "INFO"
        log_level = logging.INFO
        print(f''' WARNING: Invalid log level "{args.PY_LOG_LEVEL.upper()}", set to INFO.''')
    print(f''' Python Log Level= str: {log_level_str}, attr: {log_level}''')
    logging.basicConfig(format='%(levelname)s::%(pathname)s::L%(lineno)d::%(message)s', level=log_level)

    yyyymmdd = args.yyyymmdd
    yyyy = yyyymmdd[:4]
    mm = yyyymmdd[4:6]
    dd = yyyymmdd[6:8]

    logging.info(f"YYYY:{yyyy}, MM:{mm}, DD:{dd}")

    input_dir_path = args.input_dir_path
    fn_nc1 = f"era5_{yyyy}{mm}{dd}_avg.nc"
    fn_nc2 = f"era5_{yyyy}{mm}{dd}_instant.nc"
    fn_output = f"ERA5_forcing_{yyyy}-{mm}-{dd}_fix.nc"

    file1_path = os.path.join(input_dir_path, fn_nc1)
    file2_path = os.path.join(input_dir_path, fn_nc2)
    output_path = os.path.join(input_dir_path, fn_output)

    create_netcdf_from_files(file1_path, file2_path, output_path)
