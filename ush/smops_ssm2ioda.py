#!/usr/bin/env python3
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
import os
import argparse
import netCDF4 as nc
import numpy as np
import re
from datetime import datetime, timedelta
import sys

jedi_iodaconv_path = os.environ.get('JEDI_IODACONV_PATH')
print(f'''jedi_iodaconv_path: {jedi_iodaconv_path}''')
sys.path.append(jedi_iodaconv_path)
print(f'''sys.path: {sys.path}''')

import pyiodaconv.ioda_conv_engines as iconv
from collections import defaultdict, OrderedDict
from pyiodaconv.orddicts import DefaultOrderedDict

float_missing_value = iconv.get_default_fill_val(np.float32)

os.environ["TZ"] = "UTC"

locationKeyList = [
    ("latitude", "float"),
    ("longitude", "float"),
    ("depthBelowSoilSurface", "float"),
    ("dateTime", "long")
]

obsvars = {
    'soil_moisture': 'soilMoistureVolumetric',
}

AttrData = {
}

DimDict = {
}

VarDims = {
    'soilMoistureVolumetric': ['Location'],
}

iso8601_string = 'seconds since 1970-01-01T00:00:00Z'
epoch = datetime.fromisoformat(iso8601_string[14:-1])
# Usual reference time for these data is off j2000 base
# really, I'm seeing j2000 is from noon why 11:58:55.816?
j2000_string = 'second since 2000-01-01T11:58:55Z'
j2000_base_date = datetime(2000, 1, 1, 11, 58, 55, 816)


class smops(object):
    def __init__(self, args):
        self.filename = args.input
        self.mask = args.maskMissing
        self.assumedSoilDepth = args.assumedSoilDepth
        self.varDict = defaultdict(lambda: defaultdict(dict))
        self.outdata = defaultdict(lambda: DefaultOrderedDict(OrderedDict))
        self.varAttrs = defaultdict(lambda: DefaultOrderedDict(OrderedDict))
        self._read()

    # Open input file and read relevant info
    def _read(self):
        # set up variable names for IODA
        for iodavar in ['soilMoistureVolumetric']:
            self.varDict[iodavar]['valKey'] = iodavar, iconv.OvalName()
            self.varDict[iodavar]['errKey'] = iodavar, iconv.OerrName()
            self.varDict[iodavar]['qcKey'] = iodavar, iconv.OqcName()
            self.varAttrs[iodavar, iconv.OvalName()]['_FillValue'] = float_missing_value
            self.varAttrs[iodavar, iconv.OerrName()]['_FillValue'] = float_missing_value
            self.varAttrs[iodavar, iconv.OvalName()]['coordinates'] = 'longitude latitude'
            self.varAttrs[iodavar, iconv.OerrName()]['coordinates'] = 'longitude latitude'
            self.varAttrs[iodavar, iconv.OqcName()]['coordinates'] = 'longitude latitude'
            self.varAttrs[iodavar, iconv.OvalName()]['units'] = 'm3 m-3'
            self.varAttrs[iodavar, iconv.OerrName()]['units'] = 'm3 m-3'

        # open input file name
        ncd = nc.Dataset(self.filename, 'r')
        # set and get global attributes
        satelliteID = 789
        sensorID = 432
        AttrData["platform"] = np.array([satelliteID], dtype=np.int32)
        AttrData["sensor"] = np.array([sensorID], dtype=np.int32)

        data = ncd.variables['sm'][:].ravel()
        vals = data[:].ravel()
        vals[vals == -9999.] = float_missing_value
        _FillValue = ncd.variables['sm'].getncattr('_FillValue')
        valid_max = 1. #ncd.variables['sm'].getncattr('valid_max')
        valid_min = 0. #ncd.variables['sm'].getncattr('valid_min')

        lat = ncd.variables['lat'][:].ravel()
        lon = ncd.variables['lon'][:].ravel()

        lat_ = np.zeros((len(lat), len(lon)))
        lon_ = np.zeros((len(lat), len(lon)))

        lat_[:] = lat[:, np.newaxis]
        lon_[:] = lon        

        lats = lat_[:]
        lons = lon_[:]

        errs = np.full_like(vals, 2.0) #ncd.variables['error'][:].ravel()
        qflg = ncd.variables['q_flag'][:].ravel()
        times = get_observation_time(self.filename, ncd, vals)
        sflg_present, sflg, vegop, erowi, ecoli = get_ease_surface_param(ncd)
        deps = np.full_like(vals, self.assumedSoilDepth)

        if self.mask:
            with np.errstate(invalid='ignore'):
                mask = (vals > valid_min) & (vals < valid_max)
            vals = vals[mask]
            lats = lats[mask]
            lons = lons[mask]
            deps = deps[mask]
            errs = errs[mask]
            qflg = qflg[mask]
            times = times[mask]
            if sflg_present:
                sflg = sflg[mask]
                vegop = vegop[mask]
                erowi = erowi[mask]
                ecoli = ecoli[mask]
        # set fillValue to IODA missing
        vals[vals == _FillValue] = float_missing_value

        vals = vals.astype('float32')
        lats = lats.astype('float32')
        lons = lons.astype('float32')
        deps = deps.astype('float32')
        # reassign to constant (could be pass in)
        errs[:] = 0.04
        errs = errs.astype('float32')
        qflg = qflg.astype('int32')
        if sflg_present:
            sflg = sflg.astype('int32')
            vegop = vegop.astype('float32')
            erowi = erowi.astype('int32')
            ecoli = ecoli.astype('int32')

        # add metadata variables
        self.outdata[('dateTime', 'MetaData')] = times
        self.varAttrs[('dateTime', 'MetaData')]['units'] = iso8601_string
        self.outdata[('latitude', 'MetaData')] = lats
        self.varAttrs[('latitude', 'MetaData')]['units'] = 'degree_north'
        self.outdata[('longitude', 'MetaData')] = lons
        self.varAttrs[('longitude', 'MetaData')]['units'] = 'degree_east'
        self.outdata[('depthBelowSoilSurface', 'MetaData')] = deps
        self.varAttrs[('depthBelowSoilSurface', 'MetaData')]['units'] = 'm'
        if sflg_present:
            self.outdata[('surfaceQualifier', 'MetaData')] = sflg
            self.outdata[('vegetationOpacity', 'MetaData')] = vegop
            self.outdata[('easeRowIndex', 'MetaData')] = erowi
            self.outdata[('easeColumnIndex', 'MetaData')] = ecoli

        for iodavar in ['soilMoistureVolumetric']:
            self.outdata[self.varDict[iodavar]['valKey']] = vals
            self.outdata[self.varDict[iodavar]['errKey']] = errs
            self.outdata[self.varDict[iodavar]['qcKey']] = qflg

        DimDict['Location'] = len(self.outdata[('dateTime', 'MetaData')])


def get_observation_time(filename, ncd, vals):
    # get observation time from file if present fallback to extraction from filename
    if 'time' in ncd.variables.keys():
        atime = ncd.variables['time'][:] # seconds since 1970-01-01 00:00:00
        times = np.full_like(vals, atime, dtype=np.int64)
    else:
        # needs to update according to SMOPS file s/e format
        atime = round((datetime.strptime(re.search(r"(\d{8}T\d{6})(?!.*\d{8}T\d{6})", filename).group(),
                      "%Y%m%dT%H%M%S") - epoch).total_seconds())
        times = np.full_like(vals, atime, dtype=np.int64)

    return times


def get_ease_surface_param(ncd):
    sflg_present = False
    # retrieve surface EASE grid parameters if present
    sflg = None
    vegop = None
    erowi = None
    ecoli = None
    if 'surface_flag' in ncd.variables.keys() and \
       'vegetation_opacity' in ncd.variables.keys() and \
       'EASE_row_index' in ncd.variables.keys() and \
       'EASE_column_index' in ncd.variables.keys():
        sflg_present = True
        sflg = ncd.variables['surface_flag'][:].ravel()
        vegop = ncd.variables['vegetation_opacity'][:].ravel()
        erowi = ncd.variables['EASE_row_index'][:].ravel()
        ecoli = ncd.variables['EASE_column_index'][:].ravel()
    return sflg_present, sflg, vegop, erowi, ecoli


def main():

    parser = argparse.ArgumentParser(
        description=('Read SMOPS surface soil moisture file(s) and Converter'
                     ' of native netCDF format for observations of surface'
                     ' soil moisture to IODA netCDF format.')
    )
    parser.add_argument('-i', '--input',
                        help="name of smops surface soil moisture input file(s)",
                        type=str, required=True)
    parser.add_argument('-o', '--output',
                        help="name of ioda output file",
                        type=str, required=True)
    optional = parser.add_argument_group(title='optional arguments')
    optional.add_argument(
        '--maskMissing',
        help="switch to mask missing values: default=False",
        default=False, action='store_true', required=False)
    optional.add_argument(
        '--assumedSoilDepth',
        help="default assumed depth of soil moisture in meters",
        type=float, default=0.025, required=False)

    args = parser.parse_args()

    # Read in the SMOPS volumetric soil moisture data
    ssm = smops(args)

    # setup the IODA writer
    writer = iconv.IodaWriter(args.output, locationKeyList, DimDict)

    # write everything out
    writer.BuildIoda(ssm.outdata, VarDims, ssm.varAttrs, AttrData)


if __name__ == '__main__':
    main()
