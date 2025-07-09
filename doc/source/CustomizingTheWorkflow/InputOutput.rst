.. _IO:

*******************************************
Input/Output Files for the Land DA System
*******************************************

This chapter provides practical information on input and output files and parameters for the Land DA System, including the UFS Weather Model, its Noah-MP Land Surface Model (LSM) component, and the JEDI data assimilation (DA) system.
For background information on the Noah-MP LSM and other components, see :numref:`Chapter %s <Components>`. 

.. _view-netcdf-files:

Viewing netCDF Files
***********************

Many Land DA System input and output files are in NetCDF format. Users can view file information, variables, and notes for NetCDF files using the ``ncdump`` module. The ``-h`` option provides summary ("header") information. On :ref:`Level 1 platforms <level1>`, users can load the Land DA environment from ``land-DA_workflow``:

.. include:: ../doc-snippets/load-env.rst

Then, users can load ``netcdf`` and run ``ncdump -h path/to/filename.nc``, where ``path/to/filename.nc`` is replaced with the path to the file. For example, on Hercules, users might run: 

.. code-block:: console

   module load netcdf-c/4.9.2
   ncdump -h /work/noaa/epic/UFS_Land-DA_v2.1/inputs/NOAHMP_IC/ufs-land_C96_init_fields.tile1.nc


On other systems, users can load a compiler, MPI, and NetCDF modules before running the ``ncdump`` command above. For example: 

.. code-block:: console

   module load intel/2022.1.2 impi/2022.1.2 netcdf/4.7.0
   ncdump -h /path/to/inputs/NOAHMP_IC/ufs-land_C96_init_fields.tile1.nc

Users may need to modify the ``module load`` command to reflect modules that are available on their system. 

.. _InputFiles:

Input Files 
**************

Obtaining Data
================

The `Land DA data bucket <https://registry.opendata.aws/noaa-ufs-land-da/>`_ contains input files required for cases described in the Land DA System documentation. These files are publicly available, and users can download the data and untar the files via the command line using ``wget`` (or via the `Amazon Web Services [AWS] Command Line Interface [CLI] <https://docs.aws.amazon.com/cli/>`_):

.. _TarFile:

.. code-block:: console

   wget https://noaa-ufs-land-da-pds.s3.amazonaws.com/CADRE-2025/Land-DA_v2.1_inputs.tar.gz
   tar xvfz Land-DA_v2.1_inputs.tar.gz

For data specific to the latest release (|latestr|), users can run: 

.. code-block:: console
   
   wget https://noaa-ufs-land-da-pds.s3.amazonaws.com/current_land_da_release_data/v2.0.0/LandDAInputDatav2.0.0.tar.gz
   tar xvfz LandDAInputDatav2.0.0.tar.gz

These files and their parameters are described in the following subsections.


.. _wm-noahmp-input:

The UFS Weather Model and Noah-MP Land Component Files
=========================================================

Input Files Required by Noah-MP (All Configurations)
------------------------------------------------------

The Noah-MP LSM requires multiple input files to run, including static datasets (fix files containing climatological information, terrain, and land use data) and initial conditions files. Users may reference the `Community Noah-MP Land Surface Modeling System Technical Description Version 5.0 <https://opensky.ucar.edu/islandora/object/%3A3912>`_ (2023) for a detailed technical description of certain elements of the Noah-MP model.

In Noah-MP, the static file(s) and initial conditions file(s) specify model parameters. These files are required for all configurations of the Land DA System. 

Noah-MP Initial Conditions
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The initial conditions files include the initial state variables that are required for the UFS land snow DA to begin a cycling run. The data must be provided in :term:`netCDF` format. 

By default, on Level 1 systems and in the Land DA data bucket, the initial conditions files are located at ``inputs/NOAHMP_IC/ufs-land_C96_init_fields.tile*.nc`` (downloaded :ref:`above <InputFiles>`). Each file corresponds to one of the six tiles of the `global FV3 grid <https://www.gfdl.noaa.gov/fv3/fv3-grids/>`_.  

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

.. _fv3-fix-tiled:

FV3_fix_tiled Files
^^^^^^^^^^^^^^^^^^^^^

The UFS land component also requires a series of tiled static (fix) files that will be used by the component model. These files contain information on maximum snow albedo, slope type, soil color and type, substrate temperature, vegetation greenness and type, and orography (grid and land mask information). These files are located in the ``inputs/FV3_fix_tiled/C96`` directory (downloaded :ref:`above <InputFiles>`). 

.. code-block:: console

   C96.facsf.tile*.nc
   C96_grid.tile*.nc
   C96.maximum_snow_albedo.tile*.nc 
   C96.slope_type.tile*.nc
   C96.snowfree_albedo.tile*.nc
   C96.soil_type.tile*.nc
   C96.soil_color.tile*.nc
   C96.substrate_temperature.tile*.nc
   C96.vegetation_greenness.tile*.nc
   C96.vegetation_type.tile*.nc
   C96_oro_data.tile*.nc
   C96_oro_data_ss.tile*.nc
   C96_oro_data_ls.tile*.nc
   C96_grid_spec.nc
   C96_mosaic.nc

The ``C96_grid.tile*.nc`` files contain grid information for tiles 1-6 at C96 grid resolution. The ``C96_grid_spec.nc`` file contains information on the mosaic grid. 

.. note:: 

   The ``C96_grid_spec.nc`` and ``C96_mosaic.nc`` files are the same file under different names and may be used interchangeably. 


.. _datm-lnd-input-files:

Forcing Files for the LND (``DATM`` + ``LND``) Configuration 
--------------------------------------------------------------

In the :term:`LND` configuration of the Land DA System, users can choose to use :term:`ERA5` atmospheric forcing data or :term:`GSWP3` atmospheric forcing data. Several :github:`pre-configured <tree/develop/parm/config_samples>` LND cases are available in the Land DA repository: 

.. list-table:: Preconfigured LND Cases
   :header-rows: 1

   * - File Name
     - Data Forcing
     - JEDI Algorithm
     - Observation Data 
     - Start Type
     - DATE_FIRST_CYCLE
     - Number of 24-hr Cycles
   * - config.LND.era5.3dvar.ims.warmstart.yaml
     - ERA5
     - 3dvar
     - IMS
     - warm
     - 2025-01-19 00z
     - 2
   * - config.LND.era5.letkfoi.ghcn.coldstart.yaml
     - ERA5
     - letkf-oi
     - GHCN
     - cold
     - 2025-01-17 00z
     - 2
   * - config.LND.era5.letkfoi.smap.warmstart.yaml (in testing; not yet fully functional)
     - ERA5
     - letkf-oi
     - SMAP
     - warm
     - 2025-01-19 00z
     - 1
   * - config.LND.gswp3.3dvar.ghcn.coldstart.yaml
     - GSWP3
     - 3dvar
     - GHCN
     - cold
     - 2000-01-30 00z
     - 3
   * - config.LND.gswp3.letkfoi.ghcn.warmstart.yaml
     - GSWP3
     - letkf-oi
     - GHCN
     - warm
     - 2000-02-02 00z
     - 2

On Level 1 platforms, the requisite data are pre-staged at the locations listed in :numref:`Section %s <Level1Data>`. The data are also publicly available via the `Land DA Data Bucket <https://registry.opendata.aws/noaa-ufs-land-da/>`_. 

GSWP3 Forcing Files
^^^^^^^^^^^^^^^^^^^^^

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

ERA5 Forcing Files
^^^^^^^^^^^^^^^^^^^^^

:term:`ECMWF` Reanalysis v5 (ERA5) :term:`forcing files<forcing data>` for the :term:`LND` configuration are located in the ``inputs/DATM_input_data/era5`` directory (downloaded :ref:`above <InputFiles>`).

.. code-block:: console

   ERA5_forcing_2010-12-31_fix.nc
   ERA5_forcing_2011-01-01_fix.nc
   ERA5_forcing_2011-01-02_fix.nc
   ERA5_forcing_2025-01-16_fix.nc
   ERA5_forcing_2025-01-17_fix.nc
   ERA5_forcing_2025-01-19_fix.nc
   ERA5_forcing_2025-01-20_fix.nc
   ERA5_forcing_2025-01-21_fix.nc
   ERA5_forcing_2025-01-23_fix.nc
   ERA5_mesh.nc

These files provide atmospheric forcing data related to precipitation, solar radiation, longwave radiation, temperature, surface pressure, wind speed, specific humidity, and mesh data. 

.. _atml-input-files:

Input Files for the ``FV3`` + ``LND`` Configuration
------------------------------------------------------

In the :term:`ATML` configuration of the Land DA System, users run with the active :term:`FV3` atmospheric component. :github:`Pre-configured <tree/develop/parm/config_samples>` ATML cases are available in the Land DA repository: 

.. list-table:: Preconfigured ATML Cases
   :header-rows: 1

   * - File Name
     - JEDI Algorithm
     - Observation Data 
     - Start Type
     - DATE_FIRST_CYCLE
     - Number of 24-hr Cycles
   * - config.ATML.3dvar.ghcn.coldstart.yaml
     - 3dvar
     - IMS
     - cold
     - 2022-12-21 00z
     - 2
   * - config.ATML.3dvar.ghcn.warmstart.yaml
     - letkf-oi
     - GHCN
     - warm
     - 2022-12-23 00z
     - 2

The FV3 component requires global fix files and initial conditions files. On Level 1 platforms, the requisite data are pre-staged at the locations listed in :numref:`Section %s <Level1Data>`. The data are also publicly available via the `Land DA Data Bucket <https://registry.opendata.aws/noaa-ufs-land-da/>`_. 

Global Fix Files
^^^^^^^^^^^^^^^^^^

Global fix file data for the :term:`FV3` component are required to run the :term:`ATML` configurations. They are located in the ``inputs/FV3_fix_global`` directory (downloaded :ref:`above <InputFiles>`). 

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
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Input data from GDAS or GFS is required to run the :term:`ATML` configurations. The data are located in the ``inputs/DATA_[gdas|gfs]`` directories (downloaded :ref:`above <InputFiles>`) and are used as initial conditions for the ``fcst_ic`` task. The :github:`exlandda_fcst_ic.sh <blob/develop/scripts/exlandda_fcst_ic.sh>` script sets the default path to this data using the ``COMINgdas`` and ``COMINgfs`` variables. The operational :nco:`WCOSS Implementation Standards <>` designate ``COMIN*`` directories as directories containing input data for the model indicated in the directory name (e.g., ``COMINgfs`` contains input data for the GFS model). In addition, these directories (``DATA_[gdas|gfs]``) contain the IMS raw data files. Within each ``COMIN*`` directory, data is organized by cycle date. For example, for ``20250119``, the following data is present in the ``DATA_gdas/20250119`` directory: 

.. code-block:: console

   gdas.t00z.imssnow96.asc
   gdas.t00z.imssnow96.grib2
   gdas.t00z.sfcsno.tm00.bufr_d
   gdas.t00z.snocvr.tm00.bufr_d

Input Files for the JEDI DA System
===================================== 

The Land DA System requires grid description files, observation files, and restart files to perform snow DA. 

Grid Description Files
------------------------

The grid description files appear in :numref:`Table %s <GridInputFiles>` below: 

.. _GridInputFiles:

.. list-table:: Input Files Containing Grid Information
   :widths: 30 70
   :header-rows: 1

   * - Filename
     - Description
   * - Cxx_grid.tile[1-6].nc
     - Cxx grid information for tiles 1-6, where ``xx`` is the grid resolution.
   * - Cxx_oro_data.tile[1-6].nc
       
       oro_Cxx.mx100.tile[1-6].nc (former name/synonym)

     - Orography files that contain grid and land mask information. 
       Cxx refers to the atmospheric resolution, and mx100 refers to the ocean 
       resolution (100=1º). Both file names refer to the same file. 

All of these files are also required for the model and are listed in :numref:`Section %s <fv3-fix-tiled>`. 

.. _observation-data:

Observation Data
-------------------

The Land DA System can use observation data in :term:`GHCN`, :term:`IMS`, and :term:`SFCSNO` format. Soil Moisture Active Passive (:term:`SMAP`) data will soon be available for soil moisture DA, but this is currently a work in progress. Instructions for downloading the data are provided in :numref:`Section %s <GetDataC>`, and instructions for accessing the data on :ref:`Level 1 Systems <LevelsOfSupport>` are provided in :numref:`Section %s <GetData>`. Currently, data is primarily drawn from the `Global Historical Climatology Network <https://www.ncei.noaa.gov/products/land-based-station/global-historical-climatology-network-daily>`_ (GHCN) and the U.S. National Ice Center (USNIC) Interactive Multisensor Snow and Ice Mapping System (`IMS <https://usicecenter.gov/Products/ImsHome>`_). GHCN and IMS data are available in the ``inputs/DA_obs`` directory. These data are converted to :ref:`IODA <IODA>` format in the ``prep_data`` task. 

In each experiment, the ``land_analysis.yaml`` file sets the type(s) of observation files to be used in the experiment via the ``OBS_*_SNOW`` variables (based on selections in ``config.yaml``). Before assimilation, the files for the specified observation type are copied to the run directory (usually ``$LANDDAROOT/ptmp/test_*/com/landda/$model_ver/landda.$PDY$cyc/obs`` by default --- see :numref:`Section %s <nco-dir-entities>` for more on these variables), sometimes with a naming-convention change (e.g., ``ghcn_snwd_ioda_${YYYY}${MM}${DD}.nc`` to ``ghcn_snow_${YYYY}${MM}${DD}${HH}.nc``). 

.. _ghcn-io:

GHCN Snow Depth Files
^^^^^^^^^^^^^^^^^^^^^^

Snow depth observations can be taken from the `Global Historical Climatology Network <https://www.ncei.noaa.gov/products/land-based-station/global-historical-climatology-network-daily>`_ (GHCN), which provides daily climate summaries sourced from a global network of 100,000 stations. NOAA's `NCEI <https://www.ncei.noaa.gov/>`_ provides access to these snow depth and snowfall measurements through daily-generated individual station ASCII files or GZipped tar files of full-network observations on the NCEI server or Climate Data Online. Alternatively, users may acquire yearly tarballs via ``wget``:

.. code-block:: console

   wget https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/by_year/{YYYY}.csv.gz 

where ``${YYYY}`` is replaced with the year of interest. Note that these yearly tarballs contain all measurement types from the daily GHCN output, and thus, snow depth must be manually extracted from this broader data set.

These raw snow depth observations need to be converted into IODA-formatted netCDF files for ingestion into the JEDI DA system. This process is handled in the ``prep_data`` task using the ``ush/ghcn_snod2ioda.py`` utility script. 

A selection of GHCN files is available in the ``inputs/DA_obs/GHCN/${YEAR}`` directories; files are structured as follows (using 20250119 as an example):

.. code-block:: console
   
   netcdf ghcn_snow_2025011900 {
   dimensions:
      Location = UNLIMITED ; // (9178 currently)
   variables:
      int64 Location(Location) ;
         Location:suggested_chunk_dim = 9178LL ;

   // global attributes:
         string :_ioda_layout = "ObsGroup" ;
         :_ioda_layout_version = 0 ;
         string :date_time_string = "2025-01-18T18:00:00+00:00Z" ;
         :nlocs = 9178 ;

   group: MetaData {
      variables:
         int64 dateTime(Location) ;
            dateTime:_FillValue = -9223372036854775806LL ;
            string dateTime:units = "seconds since 1970-01-01T00:00:00Z" ;
         float latitude(Location) ;
            latitude:_FillValue = 9.96921e+36f ;
            string latitude:units = "degrees_north" ;
         float longitude(Location) ;
            longitude:_FillValue = 9.96921e+36f ;
            string longitude:units = "degrees_east" ;
         float stationElevation(Location) ;
            stationElevation:_FillValue = 9.96921e+36f ;
            string stationElevation:units = "m" ;
         string stationIdentification(Location) ;
            string stationIdentification:_FillValue = "" ;
      } // group MetaData

   group: ObsError {
      variables:
         float totalSnowDepth(Location) ;
            totalSnowDepth:_FillValue = 9.96921e+36f ;
            string totalSnowDepth:coordinates = "longitude latitude" ;
            string totalSnowDepth:units = "mm" ;
      } // group ObsError

   group: ObsValue {
      variables:
         float totalSnowDepth(Location) ;
            totalSnowDepth:_FillValue = 9.96921e+36f ;
            string totalSnowDepth:coordinates = "longitude latitude" ;
            string totalSnowDepth:units = "mm" ;
      } // group ObsValue
   
   group: PreQC {
      variables:
         int totalSnowDepth(Location) ;
            totalSnowDepth:_FillValue = -2147483647 ;
            string totalSnowDepth:coordinates = "longitude latitude" ;
      } // group PreQC
   }
   

The primary observation variable is ``totalSnowDepth``, which, along with the metadata fields of ``datetime``, ``latitude``, ``longitude``, ``stationElevation``, and ``stationIdentification`` is defined along the ``nlocs`` dimension. Also present are ``ObsError``, ``ObsValue``, and ``PreQC`` values corresponding to each ``totalSnowDepth`` measurement on ``nlocs``. The magnitude of ``nlocs`` varies between files; this is due to the fact that the number of stations reporting snow depth observations for a given day can vary in the GHCN.

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

Soil Moisture Active Passive Data (`SMAP <https://nsidc.org/data/smap>`_) "includes data products derived from an L-band radiometer and high-resolution L-band radar instrument that make up the orbiting observatory of the Soil Moisture Active Passive (SMAP) satellite mission." Currently, the Land DA System only performs snow DA, but developers are in the process of adding soil moisture DA functionality to the repository. This functionality will use SMAP observations, which can be obtained from the `National Snow and Ice Data Center <https://nsidc.org/data/smap/data?field_data_set_keyword_value=3>`_. The ``ush`` directory contains two utility scripts that will be used by the ``prep_data`` task to convert SMAP soil moisture data to IODA format: ``smap_ioda_concat_files.py`` and ``smap_ssm2ioda.py``. 

.. _restart:

Restart Files
---------------

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

Restart files are located in the ``inputs/DATA_RESTART`` directory (downloaded :ref:`above <InputFiles>` from the data bucket). Each forecast cycle also outputs restart files that can be used as input for the next cycle date(s). These restart files will appear in the ``/ptmp/test_*/com/landda/v<X.Y.Z>/landda.${PDY}/RESTART`` directory. 

Output Files
*************

Output files for each cycle appear in the ``$LANDDAROOT/ptmp/test_*/com/landda/v<X.Y.Z>/landda.${PDY}`` directory. Users can also reach this directory via a shortcut in the experiment directory: ``$LANDDAROOT/exp_case/lnd_era5_warmstart_00/com_dir/landda.${PDY}``. This directory contains subdirectories with experiment output for each cycle: 

* hofx
* plot
* RESTART

The ``hofx`` directory contains information from the data assimilation that is used by the plotting tasks to create plots, which are stored in the ``plot`` directory. The ``RESTART`` directory contains :ref:`RESTART files <restart>` for the next cycle. 