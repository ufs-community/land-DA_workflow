.. _IO:

*******************************************
Input/Output Files for the Land DA System
*******************************************

This chapter provides practical information on input and output files and parameters for the Land DA System, including the UFS Weather Model, its Noah-MP Land Surface Model (LSM) component, and the JEDI data assimilation (DA) system. 

.. contents::

.. _data-overview:

Data Overview
***************

The Land DA System requires the following files for each case/configuration:

   * For all cases:
      * NOAH-MP initial conditions (ICs) files
      * FV3 fix files (tiled)
      * JEDI input fix files
      * Observation data files (:term:`IMS`, :term:`GHCN`, :term:`SMAP`, :term:`SMOPS`)
      * Cartopy Natural Earth files (only if running the plotting task)
   * For LND cases:
      * Forcing files (ERA5 or GSWP3)
   * For ATML cases:
      * FV3 fix files (global)
   * For coldstart cases:
      * Model output from a previous model run (e.g., from GDAS, GFS, SMAP, or SMOPS).
   * For warmstart cases: 
      * Restart files from a model run starting the cycle before the user's selected date (e.g., RESTART files from a WM run)

These files will be described in more detail throughout this chapter. Users can download many of these files from the `Land DA data bucket <https://registry.opendata.aws/noaa-ufs-land-da/>`_ using the instructions provided in the :ref:`next section <sample-case-data>`. 

.. _sample-case-data:

Data for Sample Cases
=======================

The `Land DA data bucket <https://registry.opendata.aws/noaa-ufs-land-da/>`_ contains input files required for cases described in the Land DA System documentation. These files are publicly available, and users can download the data and untar the files via the command line using ``wget`` (or via the `Amazon Web Services [AWS] Command Line Interface [CLI] <https://docs.aws.amazon.com/cli/>`_):

.. _tar-file:

.. code-block:: console

   wget https://noaa-ufs-land-da-pds.s3.amazonaws.com/current_land_da_release_data/v3.0.0/LandDAInputDatav3.0.0.tar.gz
   tar xvfz LandDAInputDatav3.0.0.tar.gz

These files and their parameters are described in the following subsections. Although this download provides all files needed to run the provided sample cases, users wishing to configure their own cases will need to read :numref:`Section %s <InputFiles>` to determine what additional data they may need to download and where to find it. 


.. _user-defined-case-data:

Obtaining Data for User-Defined Cases
=======================================

In theory, users can run the Land DA System for dates other than the sample cases provided. This is not yet a supported feature, but users are welcome to try it after running the provided sample cases successfully. However, user-defined cases may require significant troubleshooting. Users may reach out through `GitHub Discussions Q & A <https://github.com/ufs-community/land-DA_workflow/discussions/categories/q-a>`_, and the Land DA development team will assist as time allows. The data descriptions throughout this chapter provide suggestions for how to obtain the various data required for different components of the Land DA System. 

.. _InputFiles:

Input Files 
**************

.. _data-all-configs:

Data Applicable to All Land DA Configurations
===============================================

The Noah-MP LSM requires multiple input files to run, including static datasets (fix files containing climatological information, terrain, and land use data) and initial conditions files. Users may reference the `Community Noah-MP Land Surface Modeling System Technical Description Version 5.0 <https://opensky.ucar.edu/islandora/object/%3A3912>`_ (2023) for a detailed technical description of certain elements of the Noah-MP model.

In Noah-MP, the tiled fix file(s) and initial conditions file(s) specify model parameters. These files are required for all configurations of the Land DA System. Additionally, the DA system requires JEDI fix files and observations as input. If users intend to perform plotting tasks, Cartopy Natural Earth files are also necessary. 

Noah-MP Initial Conditions
----------------------------

* Required for: All Land DA cases

The initial conditions files include the initial state variables that are required for the UFS land snow DA to begin a cycling run. The data must be provided in :term:`netCDF` format. 

By default, on Level 1 systems and in the Land DA data bucket, the initial conditions files are located at ``inputs/NOAHMP_IC/ufs-land_C96_init_fields.tile*.nc`` (downloaded in :numref:`Section %s <sample-case-data>`). Each file corresponds to one of the six tiles of the `global FV3 grid <https://www.gfdl.noaa.gov/fv3/fv3-grids/>`_.  

The files contain the following data:             

.. list-table:: Variables specified in the initial conditions files ``ufs-land_C96_init_fields.tile*.nc``
   :header-rows: 1

   * - Variables
     - Long Name
     - Units 
   * - time(time)
     - "time"
     - "seconds since 1970-01-01 00:00:00"
   * - geolat(lat, lon)
     - "latitude"
     - "degrees_north"
   * - geolon(lat, lon)
     - "longitude"
     - "degrees_east"
   * - snow_water_equivalent(time, lat, lon)
     - "snow water equivalent"
     - "mm"
   * - snow_depth(time, lat, lon)
     - "snow depth"
     - "m"
   * - canopy_water(time, lat, lon)
     - "canopy surface water"
     - "mm"
   * - skin_temperature(time, lat, lon)
     - "surface skin temperature"
     - "K"
   * - soil_temperature(time, soil_levels, lat, lon)
     - "soil temperature"
     - "K"
   * - soil_moisture(time, soil_levels, lat, lon)
     - "volumetric soil moisture"
     - "m3/m3"
   * - soil_liquid(time, soil_levels, lat, lon)
     - "volumetric soil liquid"
     - "m3/m3"

The full Land DA data bucket download (see :numref:`Section %s <sample-case-data>`) includes :term:`ICs` for Land DA in the ``inputs/NOAHMP_IC`` directory. These are essentially dummy ICs that can be used with LND and warmstart ATML cases. For :term:`ATML` coldstart cases, the ``fcst_ic`` task will generate the ICs by running the model for one cycle before performing DA, and users need not worry about staging ICs. For :term:`LND` or ATML warmstart cases, ICs must be provided. Users can use the ICs from the ``inputs/NOAHMP_IC`` directory (downloaded from the data bucket) for any case. In theory, users can also choose to use/produce their own ICs, either by running the ATML coldstart case for the cycle before the desired date or by generating them from the :term:`GDAS` results. However, this is not yet supported functionality for the Land DA System. 

.. _fv3-fix-tiled:

FV3_fix_tiled Files
---------------------

* Required for: All Land DA cases (currently supported only for C96 resolution)

The UFS land component also requires a series of tiled static (fix) files that will be used by the component model. These files are resolution-dependent and contain information on maximum snow albedo, slope type, soil color and type, substrate temperature, vegetation greenness and type, and orography (grid and land mask information). These files are located in the ``inputs/FV3_fix_tiled/C96`` directory (downloaded in :numref:`Section %s <sample-case-data>`). They should be used even for user-defined cases, since they do not change from case to case. 

.. code-block:: console

   C96.facsf.tile*.nc
   C96_grid.tile*.nc
   C96.maximum_snow_albedo.tile*.nc 
   C96.slope_type.tile*.nc
   C96.snowfree_albedo.tile*.nc
   C96.soil_color.tile*.nc
   C96.soil_type.tile*.nc
   C96.substrate_temperature.tile*.nc
   C96.vegetation_greenness.tile*.nc
   C96.vegetation_type.tile*.nc
   C96_oro_data.tile*.nc
   C96_oro_data_ss.tile*.nc
   C96_oro_data_ls.tile*.nc
   C96_grid_spec.nc
   C96_mosaic.nc

The ``C96_grid.tile*.nc`` files contain grid information for tiles 1-6 at C96 grid resolution and were formerly named ``oro_Cxx.mx100.tile*.nc`` (where mx100 refers to the ocean resolution (100=1º)). The ``C96_grid_spec.nc`` file contains information on the mosaic grid. 

.. note:: 

   The ``C96_grid_spec.nc`` and ``C96_mosaic.nc`` files are the same file under different names and may be used interchangeably. 

.. note::

   The ``inputs`` data directory also contains data for C192 and C384 resolution, but running at these higher resolutions is currently unsupported functionality. 


.. _jedi-fix-fv3files:

Fixed JEDI Input Files
------------------------ 

* Required for: All Land DA cases

The JEDI DA component of the Land DA System requires several fixed ``fv3files`` files as input. Most of these files are used by the JEDI :jedi:`Geometry <inside/jedi-components/fv3-jedi/classes.html#geometry>` class. 

The ``fv3files`` include: 
   * ak/bk values
   * field tables
   * namelist files

These files are explained in detail in the :jedi:`JEDI fv3files documentation <inside/jedi-components/fv3-jedi/data.html#static-data-files>`. They are available in the ``inputs/DATA_jedi_input/fv3files`` directory (downloaded in :numref:`Section %s <sample-case-data>`).

.. _observation-data:

Observation Data
-------------------

* Required for: All Land DA cases

The Land DA System can accept :term:`GHCN`, :term:`IMS`, and :term:`SFCSNO` snow observation data. It accepts :term:`SMAP` or :term:`SMOPS` soil moisture observation data. Users need only provide one type of observation data depending on whether they plan to perform snow or soil moisture data assimilation. 

Currently, snow observation data is primarily drawn from the `Global Historical Climatology Network <https://www.ncei.noaa.gov/products/land-based-station/global-historical-climatology-network-daily>`_ (GHCN) and the U.S. National Ice Center (USNIC) Interactive Multisensor Snow and Ice Mapping System (`IMS <https://usicecenter.gov/Products/ImsHome>`_). GHCN and IMS data for provided sample cases are available in the ``inputs/DA_obs`` directory. These data are converted to :ref:`IODA <IODA>` format in the ``prep_data`` task. 

Soil moisture data is primarily drawn from the National Snow and Ice Data Center `Soil Moisture Active Passive <https://nsidc.org/data/smap/data>`_ (SMAP) data set or from the NOAA `Soil Moisture Operational Products System <https://www.ospo.noaa.gov/products/land/smops/>`_ (SMOPS) data set. SMAP and SMOPS data for provided sample cases are available in the ``inputs/DATA_[smap|smops]`` directories. These data are converted to :ref:`IODA <IODA>` format in the ``prep_data`` task.

In each experiment, the ``land_analysis.yaml`` file sets the type(s) of observation files to be used in the experiment via the ``OBS_*_SNOW`` variables (based on selections in ``config.yaml``). Before assimilation, the files for the specified observation type are copied to the run directory (usually ``${BASEDIR}/ptmp/<envir>/com/landda/${model_ver}/landda.${PDY}${cyc}/obs`` by default --- see :numref:`Section %s <nco-dir-entities>` for more on these variables), sometimes with a naming-convention change (e.g., ``ghcn_snwd_ioda_${YYYY}${MM}${DD}.nc`` to ``ghcn_snow_${YYYY}${MM}${DD}${HH}.nc``).

.. _ghcn-io:

GHCN Snow Depth Files
^^^^^^^^^^^^^^^^^^^^^^

Snow depth observations can be taken from the `Global Historical Climatology Network <https://www.ncei.noaa.gov/products/land-based-station/global-historical-climatology-network-daily>`_ (GHCN), which provides daily climate summaries sourced from a global network of 100,000 stations. NOAA's `NCEI <https://www.ncei.noaa.gov/>`_ provides access to these snow depth and snowfall measurements through daily-generated individual station ASCII files or GZipped tar files of full-network observations on the NCEI server or Climate Data Online. Alternatively, users may acquire yearly tarballs via ``wget``:

.. code-block:: console

   wget https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/by_year/{YYYY}.csv.gz 

where ``${YYYY}`` is replaced with the year of interest. Note that these yearly tarballs contain all measurement types from the daily GHCN output, and thus, snow depth must be manually extracted from this broader data set.

These raw snow depth observations need to be converted into IODA-formatted netCDF files for ingestion into the JEDI DA system. This process is handled in the ``prep_data`` task using the ``ush/ghcn_snod2ioda.py`` utility script. 

A selection of GHCN files is available in the ``inputs/DA_obs/GHCN/${YEAR}`` directories. The primary observation variable is ``totalSnowDepth``, which, along with the metadata fields of ``datetime``, ``latitude``, ``longitude``, ``stationElevation``, and ``stationIdentification`` is defined along the ``nlocs`` dimension. Also present are ``ObsError``, ``ObsValue``, and ``PreQC`` values corresponding to each ``totalSnowDepth`` measurement on ``nlocs``. The magnitude of ``nlocs`` varies between files; this is due to the fact that the number of stations reporting snow depth observations for a given day can vary in the GHCN.

GHCN files for 2000, 2011, and 2025 are already provided in IODA format for the |latestr| release. :numref:`Table %s <GetData>` indicates where users can find data on NOAA :term:`RDHPCS` platforms. Tar files containing the data are located in the publicly-available `Land DA Data Bucket <https://registry.opendata.aws/noaa-ufs-land-da/>`_. Once untarred, the snow depth files are located in ``inputs/DA_obs/GHCN/${YEAR}``. Each file follows the naming convention of ``ghcn_snwd_ioda_${YYYY}${MM}${DD}.nc``, where ``${YYYY}`` is the four-digit cycle year, ``${MM}`` is the two-digit cycle month, and ``${DD}`` is the two-digit cycle day. 

.. _ims-io:

IMS Snow Depth Files
^^^^^^^^^^^^^^^^^^^^^^

The `Interactive Multisensor Snow and Ice Mapping System (IMS) <https://usicecenter.gov/Resources/ImsInfo>`_ is an "operational software package used to demarcate the presence of snow and ice across the entire northern hemisphere." It produces daily 4-km resolution maps of snow and ice in the Northern Hemisphere; these maps are distributed by the U.S. National Ice Center. Files are available in compressed ASCII format. Users can download these files from the `U.S. National Ice Center Archive <https://usicecenter.gov/Products/ArchiveSearchMulti?table=ImsAsc&linkChange=ims-two>`_. 

These raw snow depth observations need to be converted into IODA-formatted netCDF files for ingestion into the JEDI system. This process is handled in the ``prep_data`` task. First, the ASCII files are processed for the UFS model grid using the ``sorc/calcfIMS.fd`` executable, and then the output is converted into IODA format using the ``ush/ghcn_snod2ioda.py`` utility script. 

.. note::

   When the IMS option is turned on, SFCSNO files are also added because IMS data alone does not produce satisfactory results compared to GHCN data (see GitHub :github:`Issue #223 <issues/223>` and :github:`PR #224 <pull/224>`). 

.. _sfcsno-io:

SFCSNO Files
^^^^^^^^^^^^^^

SFCSNO files are Global Telecommunication System (GTS) data from :term:`GDAS`/:term:`GFS`. GTS is "[t]he co-ordinated global system of telecommunication facilities and arrangements for the rapid collection, exchange and distribution of observations and processed information within the framework of the World Weather Watch." SFCSNO files are already provided in BUFR format in the :ref:`usual locations <GetData>` on NOAA :term:`RDHPCS` platforms and in the publicly-available `Land DA Data Bucket <https://registry.opendata.aws/noaa-ufs-land-da/>`_. In both cases, they are located in the ``inputs/DATA_gdas`` directory (downloaded :ref:`above <InputFiles>` from the data bucket). Each file is named ``gdas.t00z.sfcsno.tm00.bufr_d`` and is located under the relevant cycle date (e.g., ``inputs/DATA_gdas/20250119/gdas.t00z.sfcsno.tm00.bufr_d``). IODA can read :jedi-latest:`BUFR files <inside/jedi-components/ioda/format-bufr.html>` when provided with an appropriate mapping file, such as the ``parm/jedi/bufr_sfcsno_mapping.yaml`` in the Land DA repository. The ``jedi_<algorithm>_snow.yaml`` file produced by the ``jcb`` task contains information on observations, including the IODA "engine" used to read the file (``bufr`` for BUFR files) and the path to the "mapping file." For example: 

.. code-block:: yaml

   observations:
     obs perturbations: false
     observers:
     - obs space:
       name: sfcsno
       obsdatain:
         engine:
           type: bufr
           obsfile: obs/obs.20250119.t00z.sfcsno.tm00.bufr_d
           mapping file: obs/bufr_sfcsno_mapping.yaml
           missing file action: warn
       obsdataout:
         engine:
           type: H5File
           obsfile: diags/diag.sfcsno_2025011900.nc
       simulated variables:
       - totalSnowDepth

SMAP Soil Moisture Files
^^^^^^^^^^^^^^^^^^^^^^^^^

Soil Moisture Active Passive (`SMAP <https://nsidc.org/data/smap>`_) data "includes data products derived from an L-band radiometer and high-resolution L-band radar instrument that make up the orbiting observatory of the Soil Moisture Active Passive (SMAP) satellite mission." Observations for Land DA sample cases are available in the ``inputs/DATA_smap`` directory (downloaded in :numref:`Section %s <sample-case-data>`). The ``ush`` directory contains two utility scripts that will be used by the ``prep_data`` task to convert SMAP soil moisture data to IODA format: ``smap_ioda_concat_files.py`` and ``smap_ssm2ioda.py``. 

Users can download additional observation data for specific dates of choice (31 March 2015 to present) from the `National Snow and Ice Data Center <https://nsidc.org/data/smap/data>`_. There are several ways to download this data, but these instructions will explain how to download via browser/HTTPS from the NASA Earthdata website. 

#. Before getting started, create a NASA Earthdata Login (EDL) at https://urs.earthdata.nasa.gov/. 
#. Navigate to the Earthdata page containing data for the "SMAP Enhanced L2 Radiometer half-Orbit 9km EASE-Grid Soil Moisture, Version 6"  (SPL2SMP_E) data set: https://cmr.earthdata.nasa.gov/virtual-directory/collections/C2938663676-NSIDC_CPRD/temporal. 
#. Search for the desired files by clicking through the appropriate year, month, and day links. 
#. Download all files for a given day by clicking to download. 

For additional download options, visit the `NSIDC NASA Earthdata Cloud Data Access Guide <https://nsidc.org/data/user-resources/help-center/nasa-earthdata-cloud-data-access-guide#anchor-download-to-a-local-computer-from-earthdata-cloud>`_. 

SMOPS Soil Moisture Files
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The `Soil Moisture Operational Products System <https://www.ospo.noaa.gov/products/land/smops/>`_ (SMOPS) "combines soil moisture retrievals from multi-satellites/sensors to provide a global soil moisture map with more spatial and temporal coverage." Observations for Land DA sample cases are available in the ``inputs/DATA_smops`` directory (downloaded in :numref:`Section %s <sample-case-data>`). However, users can download additional observation data for specific dates of choice from the National Environmental Satellite, Data, and Information Service (NESDIS) by navigating to the `NESDIS STAR file share <https://www.star.nesdis.noaa.gov/pub/smcd/emb/SMOPS/SMOPScdr/V2.0/>`_ and selecting/downloading data for those dates. 

Cartopy Natural Earth Files
----------------------------

The set of Natural Earth raster files and shapefiles required for Land DA System plotting tasks is available in the ``inputs/NaturalEarth`` directory (downloaded in :numref:`Section %s <sample-case-data>`). The full set of Natural Earth shapefiles can also be downloaded from the `Natural Earth website <https://www.naturalearthdata.com/downloads/>`_. 


.. _datm-lnd-input-files:

Data Required for :term:`LND` Configurations Only
===================================================

* Required for: :term:`LND` configurations (Noah-MP + :term:`DATM`)

When the NOAH-MP land component is used without an active atmospheric component, atmospheric forcing files must be provided for the data atmosphere (:term:`DATM`) component. Currently, users can choose between :term:`ERA5` atmospheric forcing data or :term:`GSWP3` atmospheric forcing data. 

Several :github:`pre-configured <tree/develop/parm/config_samples>` LND cases are available in the Land DA repository: 

.. list-table:: Preconfigured LND Cases
   :header-rows: 1

   * - File Name
     - Data Forcing
     - JEDI Algorithm
     - Observation Data 
     - Start Type
     - DATE_FIRST_CYCLE
     - Number of 24-hr Cycles
   * - config.LND.era5.3dvar.ims.DA-fcst.warmstart.yaml
     - ERA5
     - 3dvar
     - IMS
     - warm
     - 2025-01-19 00z
     - 2
   * - config.LND.era5.letkfoi.ghcn.DA-fcst.coldstart.yaml
     - ERA5
     - letkf-oi
     - GHCN
     - cold
     - 2025-01-17 00z
     - 2
   * - config.LND.era5.letkfoi.smap.free-fcst.warmstart.yaml
     - ERA5
     - letkf-oi
     - SMAP
     - warm
     - 2025-01-19 00z
     - 1
   * - config.LND.gswp3.3dvar.ghcn.DA-fcst.coldstart.yaml
     - GSWP3
     - 3dvar
     - GHCN
     - cold
     - 2000-01-30 00z
     - 3
   * - config.LND.gswp3.letkfoi.ghcn.DA-fcst.warmstart.yaml
     - GSWP3
     - letkf-oi
     - GHCN
     - warm
     - 2000-02-02 00z
     - 2
   * - config.LND.era5.letkfoi.smops.free-fcst.coldstart.yaml
     - ERA5
     - letkf-oi
     - SMOPS
     - cold
     - 2022-12-20 00z
     - 3

On Level 1 platforms, the requisite data are pre-staged at the locations listed in :numref:`Section %s <Level1Data>`. The data are also publicly available via the `Land DA Data Bucket <https://registry.opendata.aws/noaa-ufs-land-da/>`_. 

GSWP3 Forcing Files
---------------------

Global Soil Wetness Project Phase 3 (GSWP3) :term:`forcing files<forcing data>` for the :term:`LND` configuration are located in the ``inputs/DATM_input_data/gswp3`` directory (downloaded :ref:`above <InputFiles>`).

.. code-block:: console 

   clmforc.GSWP3.c2011.0.5x0.5.Prec.1999-12.nc
   clmforc.GSWP3.c2011.0.5x0.5.Prec.2000-01.nc
   clmforc.GSWP3.c2011.0.5x0.5.Prec.2000-02.nc
   clmforc.GSWP3.c2011.0.5x0.5.Solr.1999-12.nc
   clmforc.GSWP3.c2011.0.5x0.5.Solr.2000-01.nc
   clmforc.GSWP3.c2011.0.5x0.5.Solr.2000-02.nc
   clmforc.GSWP3.c2011.0.5x0.5.TPQWL.1999-12.nc
   clmforc.GSWP3.c2011.0.5x0.5.TPQWL.2000-01.nc
   clmforc.GSWP3.c2011.0.5x0.5.TPQWL.2000-02.nc
   clmforc.GSWP3.c2011.0.5x0.5.TPQWL.SCRIP.210520_ESMFmesh.nc
   fv1.9x2.5_141008_ESMFmesh.nc
   topodata_0.9x1.25_USGS_070110_stream_c151201.nc
   topodata_0.9x1.SCRIP.210520_ESMFmesh.nc

These files provide atmospheric forcing data related to precipitation, solar radiation, longwave radiation, temperature, pressure, winds, humidity, topography, and mesh data. 

Formerly, this data was available a now-defunct University of Tokyo website. It may be possible to download the GSWP3 data from the `Inter-Sectoral Impact Model Intercomparison Project <https://data.isimip.org/search/simulation_round/ISIMIP2a/product/InputData/climate_forcing/gswp3/>`_ website, but Land DA developers have not tried this method, and users download materials at their own risk. 

ERA5 Forcing Files
--------------------

:term:`ECMWF` Reanalysis v5 (ERA5) :term:`forcing files<forcing data>` for the :term:`LND` configuration are located in the ``inputs/DATM_input_data/era5`` directory (downloaded :ref:`above <InputFiles>`). They are named ``ERA5_forcing_YYYY-MM-DD_fix.nc``. Additionally, there is an ``ERA5_mesh.nc`` file:

.. code-block:: console

   ERA5_forcing_2010-12-31_fix.nc
   ERA5_forcing_2011-01-01_fix.nc
   ERA5_forcing_2011-01-02_fix.nc
   ...
   ERA5_forcing_2025-01-19_fix.nc
   ERA5_forcing_2025-01-20_fix.nc
   ERA5_forcing_2025-01-21_fix.nc
   ERA5_forcing_2025-01-23_fix.nc
   ERA5_mesh.nc

These files provide atmospheric forcing data related to precipitation, solar radiation, longwave radiation, temperature, surface pressure, wind speed, specific humidity, and mesh data. 

ERA5 Forcing Data Downloads
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Users who wish to develop a new case using different forecast/cycling dates may download ERA5 data for free from Copernicus. First, register for an account at https://cds.climate.copernicus.eu. After creating a username and password and signing in, users can navigate to the page for `ERA5 hourly data on single levels from 1940 to present <https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels?tab=download>`_. Then, select the items required for the Land DA System:

Product type: 
   * Reanalysis

Variable:
   * Under *Popular*, select:
      * 10m u-component of wind
      * 10m v-component of wind
      * 2m dewpoint temperature
      * 2m temperature
      * Surface pressure

   * Under *Mean rates*, select:
      * Mean surface downward long-wave radiation flux
      * Mean surface downward short-wave radiation flux
      * Mean total precipitation rate

Year:
   * Select year(s) of the data to download.

Month:
   * Select month(s) of the data to download.

Day:
   * Select day(s) of the data to download.

Time:
   * Click *"Select all"*

Geographical area:
   * Whole available region

Data format:
   * NetCDF4

Download format:
   * "Unarchived" or "Zip"

Read the license and click *"Accept terms"*.

Once the data is downloaded, change the file names:

.. code-block:: console

   mv data_stream-oper_stepType-avg.nc era5_[yyyymmdd]_avg.nc
   mv data_stream-oper_stepType-instant.nc era5_[yyyymmdd]_instant.nc

Move or soft link the files to the ``${BASEDIR}/land-DA_workflow/fix`` directory for the ``prep_data`` workflow task. 

.. _atml-input-files:

Input Files for the ATML (FV3 + LND) Configuration
=====================================================

* Required for: :term:`ATML` configuration (Noah-MP + :term:`FV3`)

In the :term:`ATML` configuration of the Land DA System, users run with the active :term:`FV3` atmospheric component. One :github:`Pre-configured <tree/develop/parm/config_samples>` ATML case is available in the Land DA repository: 

.. list-table:: Preconfigured ATML Cases
   :header-rows: 1

   * - File Name
     - JEDI Algorithm
     - Observation Data 
     - Start Type
     - DATE_FIRST_CYCLE
     - Number of 24-hr Cycles
   * - config.ATML.3dvar.ghcn.DA-fcst.coldstart.yaml
     - 3dvar
     - IMS
     - cold
     - 2022-12-21 00z
     - 2

The FV3 component requires global fix files and FV3 initial conditions files. On Level 1 platforms, the requisite data are pre-staged at the locations listed in :numref:`Section %s <Level1Data>`. The data are also publicly available via the `Land DA Data Bucket <https://registry.opendata.aws/noaa-ufs-land-da/>`_. 

Global Fix Files
-------------------

* Required for: :term:`ATML` configurations

Global fix file data for the :term:`FV3` component are required to run the :term:`ATML` configurations. They are located in the ``inputs/FV3_fix_global`` directory (downloaded in :numref:`Section %s <sample-case-data>`). 

.. code-block:: console

   aeroclim.m[01-12].nc
   aerosol.dat
   CCN_ACTIVATE.BIN
   co2historicaldata_[2009-2024].txt
   co2monthlycyc.txt
   freezeH2O.dat
   global_glacier.2x2.grb
   global_h2oprdlos.f77
   global_hyblev.l128.txt
   global_maxice.2x2.grb
   global_o3prdlos.f77
   global_slmask.t1534.3072.1536.grb
   global_snoclim.1.875.grb
   global_soilmgldas.statsgo.t1534.3072.1536.grb
   IMS-NIC.blended.ice.monthly.clim.grb
   optics_[BC|DU|OC|SS|SU].dat
   qr_acr_qsV2.dat
   RTGSST.1982.2012.monthly.clim.grb
   sfc_emissivity_idx.txt
   snow_bump_nicas_250km_shadowlevels_nicas.nc
   solarconstant_noaa_an.txt
   ugwp_limb_tau.nc

Note that options in brackets indicate multiple files with similar naming conventions (e.g., ``aeroclim.m[01-12].nc`` means that there are twelve files, numbered from ``aeroclim.m01.nc`` to ``aeroclim.m12.nc``).

``ATML`` Input Data for Initial Conditions Generation
-------------------------------------------------------

* Required for: :term:`ATML` coldstart cases

Input data from GDAS or GFS is required to run the :term:`ATML` configurations. The data are located in the ``inputs/DATA_[gdas|gfs]`` directories (downloaded :ref:`above <InputFiles>`) and are used as initial conditions for the ``fcst_ic`` task. The :github:`exlandda_fcst_ic.sh <blob/develop/scripts/exlandda_fcst_ic.sh>` script sets the default path to this data using the ``COMINgdas`` and ``COMINgfs`` variables. The operational :nco:`WCOSS Implementation Standards <>` designate ``COMIN*`` directories as directories containing input data for the model indicated in the directory name (e.g., ``COMINgfs`` contains input data for the GFS model). In addition, these directories (``DATA_[gdas|gfs]``) contain the IMS raw data files. Within each ``COMIN*`` directory, data is organized by cycle date. For example, for ``20250119``, the following data is present in the ``DATA_gdas/20250119`` directory: 

.. code-block:: console

   gdas.t00z.imssnow96.asc
   gdas.t00z.imssnow96.grib2
   gdas.t00z.sfcsno.tm00.bufr_d
   gdas.t00z.snocvr.tm00.bufr_d


.. _restart:

Restart Files
===============

* Required for: Warmstart cases

To restart the Land DA System successfully after land model execution, all parameters, states, and fluxes used for a subsequent time iteration are stored in a restart file. This restart file is named ``ufs_land_restart.${FILEDATE}.tile#.nc`` where ``FILEDATE`` is in YYYY-MM-DD_HH-mm-SS format and ``#`` is 1-6 (e.g., ``ufs_land_restart.2000-01-05_00-00-00.tile1.nc``). The restart file contains all the model fields and their values at a specific point in time; this information can be used to restart the model immediately to run the next cycle. The Land DA System reads the states from the restart file and replaces them after the DA step with the updated analysis. Then, this updated information is fed into the model. :numref:`Table %s <RestartFiles>` lists the fields in the Land DA restart file. 

.. _RestartFiles:

.. table:: Files Included in ``ufs_land_restart.{FILEDATE}.nc``

   +--------------------------+-----------------------------------+-----------------------+
   | Variable                 | Long name                         | Unit                  | 
   +==========================+===================================+=======================+
   | time                     | time                              | "seconds since        |
   |                          |                                   | 1970-01-01 00:00:00"  |
   +--------------------------+-----------------------------------+-----------------------+
   | timestep                 | time step                         | "seconds"             |
   +--------------------------+-----------------------------------+-----------------------+
   | vegetation_fraction      | Vegetation fraction               | "-"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | emissivity_total         | surface emissivity                | "-"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | albedo_direct_vis        | surface albedo - direct visible   | "-"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | albedo_direct_nir        | surface albedo - direct NIR       | "-"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | albedo_diffuse_vis       | surface albedo - diffuse visible  | "-"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | albedo_diffuse_nir       | surface albedo - diffuse NIR      | "-"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | temperature_soil_bot     | deep soil temperature             | "K"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | cm_noahmp                | surface exchange coefficient      | "m/s"                 |
   |                          | for momentum                      |                       |
   +--------------------------+-----------------------------------+-----------------------+
   | ch_noahmp                | surface exchange coefficient      | "m/s"                 |
   |                          | heat & moisture                   |                       |
   +--------------------------+-----------------------------------+-----------------------+
   | forcing_height           | height of forcing                 | "m"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | max_vegetation_frac      | maximum fractional coverage of    | "fraction"            |
   |                          | vegetation                        |                       |
   +--------------------------+-----------------------------------+-----------------------+
   | albedo_total             | grid composite albedo             | "fraction"            |
   +--------------------------+-----------------------------------+-----------------------+
   | snow_water_equiv         | snow water equivalent             | "mm"                  |
   +--------------------------+-----------------------------------+-----------------------+
   | snow_depth               | snow depth                        | "m"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | temperature_radiative    | surface radiative temperature     | "K"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | soil_moisture_vol        | volumetric moisture content in    | "m3/m3"               |
   |                          | soil level                        |                       |
   +--------------------------+-----------------------------------+-----------------------+
   | temperature_soil         | temperature in soil               | "K"                   |
   |                          | level                             |                       |
   +--------------------------+-----------------------------------+-----------------------+
   | soil_liquid_vol          | volumetric liquid                 | "m3/m3"               |
   |                          | content in soil level             |                       |
   +--------------------------+-----------------------------------+-----------------------+
   | canopy_water             | canopy moisture                   | "m"                   |
   |                          | content                           |                       |
   +--------------------------+-----------------------------------+-----------------------+
   | transpiration_heat       | plant transpiration               |"W/m2"                 |
   +--------------------------+-----------------------------------+-----------------------+
   | friction_velocity        | friction velocity                 | "m/s"                 |
   +--------------------------+-----------------------------------+-----------------------+
   | z0_total                 | surface roughness                 | "m"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | snow_cover_fraction      | snow cover fraction               | "fraction"            |
   +--------------------------+-----------------------------------+-----------------------+
   | spec_humidity_surface    | diagnostic specific humidity at   | "kg/kg"               |
   |                          | surface                           |                       |
   +--------------------------+-----------------------------------+-----------------------+
   | ground_heat_total        | soil heat flux                    | "W/m2"                |
   +--------------------------+-----------------------------------+-----------------------+
   | runoff_baseflow          | drainage runoff                   | "mm/s"                |
   +--------------------------+-----------------------------------+-----------------------+
   | latent_heat_total        | latent heat flux                  | "W/m2"                |
   +--------------------------+-----------------------------------+-----------------------+
   | sensible_heat_flux       | sensible heat flux                | "W/m2"                |
   +--------------------------+-----------------------------------+-----------------------+
   | evaporation_potential    | potential evaporation             | "mm/s"                |
   +--------------------------+-----------------------------------+-----------------------+
   | runoff_surface           | surface runoff                    | "mm/s"                |
   +--------------------------+-----------------------------------+-----------------------+
   | latent_heat_ground       | direct soil latent heat flux      | "W/m2"                |
   +--------------------------+-----------------------------------+-----------------------+
   | latent_heat_canopy       | canopy water latent heat flux     | "W/m2"                |
   +--------------------------+-----------------------------------+-----------------------+
   | snow_sublimation         | sublimation/deposit from snowpack | "mm/s"                |
   +--------------------------+-----------------------------------+-----------------------+
   | soil_moisture_total      | total soil column moisture        | "mm"                  |
   |                          | content                           |                       |
   +--------------------------+-----------------------------------+-----------------------+
   | precip_adv_heat_total    | precipitation advected heat -     | "W/m2"                |
   |                          | total                             |                       |
   +--------------------------+-----------------------------------+-----------------------+
   | cosine_zenith            | cosine of zenith angle            | "-"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | snow_levels              | active snow levels                | "-"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | temperature_leaf         | leaf temperature                  | "K"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | temperature_ground       | ground temperature                | "K"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | canopy_ice               | canopy ice                        | "mm"                  |
   +--------------------------+-----------------------------------+-----------------------+
   | canopy_liquid            | canopy liquid                     | "mm"                  |
   +--------------------------+-----------------------------------+-----------------------+
   | vapor_pres_canopy_air    | water vapor pressure in canopy    | "Pa"                  |
   |                          | air space                         |                       |
   +--------------------------+-----------------------------------+-----------------------+
   | temperature_canopy_air   | temperature in canopy air space   | "K"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | canopy_wet_fraction      | fraction of canopy covered by     | "-"                   |
   |                          | water                             |                       |
   +--------------------------+-----------------------------------+-----------------------+
   | snow_water_equiv_old     | snow water equivalent - before    | "mm"                  |
   |                          | integration                       |                       |
   +--------------------------+-----------------------------------+-----------------------+
   | snow_albedo_old          | snow albedo - before integration  | "-"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | snowfall                 | snowfall                          | "mm/s"                |
   +--------------------------+-----------------------------------+-----------------------+
   | lake_water               | depth of water in lake            | "mm"                  |
   +--------------------------+-----------------------------------+-----------------------+
   | depth_water_table        | depth to water table              | "m"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | aquifer_water            | aquifer water content             | "mm"                  |
   +--------------------------+-----------------------------------+-----------------------+
   | saturated_water          | aquifer + saturated soil water    | "mm"                  |
   |                          | content                           |                       |
   +--------------------------+-----------------------------------+-----------------------+
   | leaf_carbon              | carbon in leaves                  | "g/m2"                |
   +--------------------------+-----------------------------------+-----------------------+
   | root_carbon              | carbon in roots                   | "g/m2"                |
   +--------------------------+-----------------------------------+-----------------------+
   | stem_carbon              | carbon in stems                   | "g/m2"                |
   +--------------------------+-----------------------------------+-----------------------+
   | wood_carbon              | carbon in wood                    | "g/m2"                |
   +--------------------------+-----------------------------------+-----------------------+
   | soil_carbon_stable       | stable carbon in soil             | "g/m2"                |
   +--------------------------+-----------------------------------+-----------------------+
   | soil_carbon_fast         | fast carbon in soil               | "g/m2"                |
   +--------------------------+-----------------------------------+-----------------------+
   | leaf_area_index          | leaf area index                   | "m2/m2"               |
   +--------------------------+-----------------------------------+-----------------------+
   | stem_area_index          | stem area index                   | "m2/m2"               |
   +--------------------------+-----------------------------------+-----------------------+
   | snow_age                 | BATS non-dimensional snow age     | "-"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | soil_moisture_wtd        | soil water content between bottom | "m3/m3"               |
   |                          | of the soil and water table       |                       |
   +--------------------------+-----------------------------------+-----------------------+
   | deep_recharge            | deep recharge for runoff_option 5 | "m"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | recharge                 | recharge for runoff_option 5      | "m"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | temperature_2m           | grid diagnostic temperature at 2  | "K"                   |
   |                          | meters                            |                       |
   +--------------------------+-----------------------------------+-----------------------+
   | spec_humidity_2m         | grid diagnostic specific humidity | "kg/kg"               |
   |                          | at 2 meters                       |                       |
   +--------------------------+-----------------------------------+-----------------------+
   | eq_soil_water_vol        | equilibrium soil water content    | "m3/m3"               |
   +--------------------------+-----------------------------------+-----------------------+
   | temperature_snow         | snow level temperature            | "K"                   |
   +--------------------------+-----------------------------------+-----------------------+
   | interface_depth          | layer-bottom depth from snow      | "m"                   |
   |                          | surface                           |                       |
   +--------------------------+-----------------------------------+-----------------------+
   | snow_level_ice           | ice content of snow levels        | "mm"                  |
   +--------------------------+-----------------------------------+-----------------------+
   | snow_level_liquid        | liquid content of snow levels     | "mm"                  |
   +--------------------------+-----------------------------------+-----------------------+

Restart files are located in the ``inputs/DATA_RESTART`` directory (downloaded :ref:`above <InputFiles>` from the data bucket). Each forecast cycle also outputs restart files that can be used as input for the next cycle date(s). These restart files will appear in the ``/ptmp/<envir>/com/landda/v<X.Y.Z>/landda.${PDY}/RESTART`` directory. However, users can generate their own RESTART files by running a coldstart GDAS or WM experiment and using the RESTART files produced. 

.. _output-files:

Output Files
*************

Output files for each cycle appear in the ``${BASEDIR}/ptmp/<envir>/com/landda/v<X.Y.Z>/landda.${PDY}`` directory. Users can also reach this directory via a shortcut in the experiment directory: ``${BASEDIR}/exp_case/lnd_era5_warmstart_00/com_dir/landda.${PDY}``. This directory contains subdirectories with experiment output for each cycle: 

* hofx
* plot
* RESTART

The ``hofx`` directory contains information from the data assimilation that is used by the plotting tasks to create plots, which are stored in the ``plot`` directory. The ``RESTART`` directory contains :ref:`RESTART files <restart>` for the next cycle. 

.. _view-netcdf-files:

Viewing NetCDF Files
***********************

Many Land DA System input and output files are in NetCDF format. Users can view file information, variables, and notes for NetCDF files using the ``ncdump`` module. The ``-h`` option provides summary ("header") information. On :ref:`Level 1 platforms <level1>`, users can load the Land DA environment from ``land-DA_workflow``:

.. include:: ../doc-snippets/load-env.rst

Then, users can load ``netcdf`` and run ``ncdump -h path/to/filename.nc``, where ``path/to/filename.nc`` is replaced with the path to the file. For example, on Hercules, users might run: 

.. code-block:: console

   cd ${BASEDIR}/land-DA_workflow
   module use modulefiles
   module load wflow_hercules
   ncdump -h /work/noaa/epic/UFS_Land-DA_v3.0/inputs/NOAHMP_IC/ufs-land_C96_init_fields.tile1.nc

On other systems, users need to load NetCDF modules before running the ``ncdump`` command above. This may also require users to load a compiler and MPI module. For example: 

.. code-block:: console

   module load netcdf-c/4.9.2
   ncdump -h /path/to/inputs/NOAHMP_IC/ufs-land_C96_init_fields.tile1.nc

Users may need to modify the ``module load`` command to reflect modules that are available on their system. On many systems, the ``module avail`` command can show users which modules are currently available to load, while the ``module spider`` command shows all modules on the system and identifies their dependencies so that users can load them in the proper order. 
