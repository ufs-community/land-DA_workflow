#!/usr/bin/env python3

import argparse
import logging
import sys
import os
from netCDF4 import Dataset

# =================================================================== CHJ =====
def datm_rfile_info(input_fn):

    try:
        ncf = Dataset(input_fn, 'r')
        logging.info(f''' Variables in file: {ncf.variables.keys()}''')
    except FileNotFoundError:
        logging.error(f''' Input restart file {input_fn} does not exist!''')

    data = ncf.variables['filename'][:]
    ncf.close()

    logging.debug(data.shape)
    num_files, num_dates, num_strs = data.shape
    logging.info(f''' Number of dates: {num_dates}''')

    first_year, first_month = find_date_from_filename(data[0,0,:])
    if num_dates > 1:
        last_year, last_month = find_date_from_filename(data[0,-1,:])
    else:
        last_year = first_year
        last_month = first_month

    logging.info(f''' First year: {first_year}, first month: {first_month}''')
    logging.info(f''' Last  year: {last_year}, last  month: {last_month}''')

    with open("first_last_date.txt", "w") as f:
        print(first_year,first_month,last_year,last_month, sep=',', file=f)
    f.close()


# =================================================================== CHJ =====
def find_date_from_filename(data):

    if data.dtype == 'S1':
        filename = "".join(x.decode('utf-8') for x in data)
    else:
        filename = data.decode('utf-8')
    filename = filename.strip()
    logging.info(f'''File name: {filename}''')
    date_string = filename.split(".")[-2]
    logging.debug(f''' YYYY-MM: {date_string}''')
    yyyy_mm = date_string.split("-")
    yyyy = yyyy_mm[0]
    mm = yyyy_mm[-1]
    logging.debug(f''' YYYY: {yyyy}''')
    logging.debug(f''' MM: {mm}''')

    return yyyy, mm


# =================================================================== CHJ =====
def parse_args(argv):
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Extract date info from DATM restart file.")
    parser.add_argument(
            "-i",
            "--input_fn",
            dest="input_fn",
            required=True,
            help="Input DATM restart file name.",
            )
    parser.add_argument(
            "-l",
            "--loglevel",
            dest="PY_LOG_LEVEL",
            default="INFO",
            help="Python logging option only for this script. For other scripts, set it in config.yaml",
            )

    return parser.parse_args(argv)


# =================================================================== CHJ =====
if __name__ == "__main__":
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
    datm_rfile_info(
        input_fn=args.input_fn,
    )

