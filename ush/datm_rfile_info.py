#!/usr/bin/env python3

import argparse
import sys
import os
from netCDF4 import Dataset

# =================================================================== CHJ =====
def datm_rfile_info(input_fn):

    try:
        ncf = Dataset(input_fn, 'r')
        print(f''' Variables in file: {ncf.variables.keys()} ''')
    except FileNotFoundError:
        print(f''' FATAL ERROR: Input restart file {input_fn} does not exist! ''')

    data = ncf.variables['filename'][:]
    ncf.close()

    print(data.shape)
    num_files, num_dates, num_strs = data.shape
    print(f''' Number of dates: {num_dates}''')

    first_year, first_month = find_date_from_filename(data[0,0,:])
    if num_dates > 1:
        last_year, last_month = find_date_from_filename(data[0,-1,:])
    else:
        last_year = first_year
        last_month = first_month

    print(f'''First year: {first_year}, first month: {first_month}''')
    print(f'''Last  year: {last_year}, last  month: {last_month}''')

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
    print(f'''File name: {filename}''')
    date_string = filename.split(".")[-2]
    #print(f'''YYYY-MM: {date_string}''')
    yyyy_mm = date_string.split("-")
    yyyy = yyyy_mm[0]
    mm = yyyy_mm[-1]
    #print(f'''YYYY: {yyyy}''')
    #print(f'''MM: {mm}''')

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
    return parser.parse_args(argv)


# =================================================================== CHJ =====
if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    datm_rfile_info(
        input_fn=args.input_fn,
    )

