.. _Model:

=================================
Noah-MP Land Surface Model
=================================

This chapter provides practical information on building and running the Noah-MP Land Surface Model (LSM). 
It also contains information on required input files and the Vector-to-Tile Converter.
For background information on the evolution of the Unified Forecast System (:term:`UFS`) 
and the Noah-MP Land Surface Model (LSM), see :numref:`Section %s <Background>` of the Introduction. 

.. _BuildRun:

Building and Running the UFS Land Model
==========================================


.. _DownloadCode:

Clone the Repository
-----------------------

.. attention::

   To build the Land DA system in a container, continue instead to the Container Chapter. The Land DA container packages together the Land DA system with its dependencies (e.g., :term:`spack-stack`, :term:`JEDI`) and provides a uniform enviroment in which to build and run the SRW App. This approach is recommended for users not running Land DA on a supported :ref:`Level 1 <LevelsOfSupport>` system (e.g., Hera, Orion). 

.. COMMENT: Add :numref:`Chapter %s <Container>` when chapter is ready.

#. Create a directory that will be the Land DA root directory (``$LANDDAROOT``). Then clone the UFS Land DA System into it:

   .. code-block:: console

      mkdir land-da
      cd land-da
      git clone -b feature/release-v1.beta2 --recursive https://github.com/NOAA-EPIC/land-offline_workflow.git


.. _GetData:

Get Data
----------

From the ``land-da`` directory, users should download the data required to run the Land DA test experiment and untar the data. For example:

.. code-block:: console

   wget https://epic-sandbox-srw.s3.amazonaws.com/landda-data-2016.tar.gz
   tar xvfz landda-data-2016.tar.gz

The data will be located in a directory called ``inputs``.

.. COMMENT: Check name of directory. 

Build the Land DA System
--------------------------

#. ``cd`` into the workflow directory, and source the modulefiles. 

   .. code-block:: console

      cd land-offline_workflow
      source <modulefiles>

   where ``<modulefiles>`` is either ``orion.modules`` or ``hera.modules``.

   .. COMMENT: Need to make sure a hera.modules is there! 
      Hera EPICHOME is: /scratch1/NCEPDEV/nems/role.epic  


#. Create and navigate to a ``build`` directory. 

   .. code-block:: console
      
      mkdir build
      cd build

#. Run the command to configure the build system.

   .. code-block:: console

      ecbuild -DCMAKE_PREFIX_PATH="$EPICHOME/contrib/ioda-bundle/install/lib64/cmake;$EPICHOME/contrib/fv3-bundle/install/lib64/cmake" ..

#. Build the Land DA system. 

   .. code-block:: console

      make -j 8

   If the code successfully compiles, the console output should end with:
   
   .. code-block:: console

      [100%] Built target ufsLandDriver.exe
   
   Additionally, the ``build`` directory will contain several files and a ``bin`` subdirectory with three executables: 

      * ``apply_incr.exe``
      * ``ufsLandDriver.exe``
      * ``vector2tile_converter.exe``

.. _InputFiles:

Input Files 
===============

The UFS Land Model requires multiple input files to run: static datasets
(fix files containing climatological information, terrain, and land use
data), initial and boundary condition files, and model configuration
files (such as namelists). Please see the `Noah-MP User's
Guide <https://www.jsg.utexas.edu/noah-mp/files/Users_Guide_v0.pdf>`__
for a detailed description of how to run the Noah-MP model.

.. COMMENT: We talk about "statics datasets" above but then a single 
   "static file" below, which could be confusing.

There are several important files used to specify model parameters: 
the static file (``ufs-land_C96_static_fields.nc``), 
the forcing initial conditions file (``ufs-land_C96_init_fields_1hr.nc``), 
and the model configuration file (``ufs-land.namelist.noahmp``). 
These files and their parameters are described in the following subsections. 
They are publicly available as part of a tar file with Land DA data. 
Users can download the data and untar the file via the command line:

.. _TarFile:

.. code-block:: console
   
   wget https://epic-sandbox-srw.s3.amazonaws.com/land-da-data.tar.gz
   tar xvfz land-da-data.tar.gz

.. COMMENT: Change link/path after building S3 Bucket

Static File (``ufs-land_C96_static_fields.nc``)
--------------------------------------------------

The static file includes the specific information on location, time,
soil layers, and other parameters that are required for Noah-MP to run. The
data can be provided in :term:`netCDF` format.

The static file is available in the ``land-release`` :ref:`tar file above <TarFile>` at the following path:

.. code-block:: 

   land-release/forcing/C96/static/ufs-land_C96_static_fields.nc

.. COMMENT: Change link/path after building S3 Bucket

.. table:: Configuration variables specified in the static file (ufs-land_C96_static_fields.nc)

   +---------------------------+------------------------------------------+
   | Configuration Variables   | Description                              |
   +===========================+==========================================+
   | land_mask                 | land-sea mask (0-ocean, 1-land)          |
   +---------------------------+------------------------------------------+
   | vegetation_category       | vegetation type                          |
   +---------------------------+------------------------------------------+
   | soil_category             | soil type                                |
   +---------------------------+------------------------------------------+
   | slope_category            | slope type                               |
   +---------------------------+------------------------------------------+
   | albedo_monthly            | monthly albedo                           |
   +---------------------------+------------------------------------------+
   | lai_monthly (leaf area    | monthly leaf area index                  |
   | index_monthly)            |                                          |
   +---------------------------+------------------------------------------+
   | emissivity                | emissivity                               |
   +---------------------------+------------------------------------------+
   | z0_monthly                | monthly ground roughness length          |
   +---------------------------+------------------------------------------+
   | cube_tile                 |                                          |
   +---------------------------+------------------------------------------+
   | cube_i                    |                                          |
   +---------------------------+------------------------------------------+
   | cube_j                    |                                          |
   +---------------------------+------------------------------------------+
   | latitude                  | latitude                                 |
   +---------------------------+------------------------------------------+
   | longitude                 | longitude                                |
   +---------------------------+------------------------------------------+
   | elevation                 | elevation                                |
   +---------------------------+------------------------------------------+
   | deep_soil_temperature     | lower boundary soil temperature          |
   +---------------------------+------------------------------------------+
   | max_snow_albedo           | maximum snow albedo                      |
   +---------------------------+------------------------------------------+
   | gvf_monthly               | monthly green vegetation fraction (gvf)  |
   +---------------------------+------------------------------------------+
   | visible_black_sky_albedo  | visible black sky albedo                 |
   +---------------------------+------------------------------------------+
   | visible_white_sky_albedo  | visible white sky albedo                 |
   +---------------------------+------------------------------------------+
   | near_IR_black_sky_albedo  | near infrared black sky albedo           |
   +---------------------------+------------------------------------------+
   | near_IR_white_sky_albedo  | near infrared white sky albedo           |
   +---------------------------+------------------------------------------+
   | soil_level_nodes          | soil level nodes                         |
   +---------------------------+------------------------------------------+
   | soil_level_thickness      | soil level thickness                     |
   +---------------------------+------------------------------------------+

.. COMMENT: Need description for cube_tile, cube_i, and cube_j

Forcing Initial Conditions File (``ufs-land_C96_init_fields_1hr.nc``)
------------------------------------------------------------------------

Land DA currently only supports snow DA. 
The forcing initial conditions file includes specific information on location, time, 
soil layers, and other variables that are required for the UFS land snow DA cycling. 
The data can be provided in :term:`netCDF` format.

The forcing initial conditions file is available in the ``land-release`` :ref:`tar file above <TarFile>` at the following path:

.. code-block:: 

   land-release/forcing/C96/init/ufs-land_C96_init_fields_1hr.nc

.. COMMENT: Change link/path after building S3 Bucket


.. table:: Configuration variables specified in the initial forcing file (ufs-land_C96_init_fields_1hr.nc)

   +-----------------------------+----------------------------------------+
   | Configuration Variables     | Units                                  |
   +=============================+========================================+
   | time                        | seconds since 1970-01-01 00:00:00      |
   +-----------------------------+----------------------------------------+
   | date (date length)          | UTC date                               |
   +-----------------------------+----------------------------------------+
   | latitude                    | degrees north-south                    |
   +-----------------------------+----------------------------------------+
   | longitude                   | degrees east-west                      |
   +-----------------------------+----------------------------------------+
   | snow_water_equivalent       | mm                                     |
   +-----------------------------+----------------------------------------+
   | snow_depth                  | m                                      |
   +-----------------------------+----------------------------------------+
   | canopy_water                | mm                                     |
   +-----------------------------+----------------------------------------+
   | skin_temperature            | K                                      |
   +-----------------------------+----------------------------------------+
   | soil_temperature            | mm                                     |
   +-----------------------------+----------------------------------------+
   | soil_moisture               | m\ :sup:`3`/m\ :sup:`3`                |
   +-----------------------------+----------------------------------------+
   | soil_liquid                 | m\ :sup:`3`/m\ :sup:`3`                |
   +-----------------------------+----------------------------------------+
   | soil_level_thickness        | m                                      |
   +-----------------------------+----------------------------------------+
   | soil_level_nodes            | m                                      |
   +-----------------------------+----------------------------------------+

Model Configuration File (``ufs-land.namelist.noahmp``)
---------------------------------------------------------

The UFS land model uses a series of template files, combined with
user-selected settings, to create required namelists and parameter
files needed by the UFS Land DA workflow. This section describes the
options in the ``ufs-land.namelist.noahmp`` file.

Run Setup Parameters
^^^^^^^^^^^^^^^^^^^^^^

``static_file``
   Specifies the UFS land static file.

``init_file``
   Specifies the UFS land initial condition file.

``forcing_dir``
   Specifies the UFS land forcing directory.

.. COMMENT: Add recommended values for the 3 variables above based on the data we provide (once it has been cleaned up/restructured). 

``separate_output``
   Specifies whether to enable a separate output directory. Valid values: ``.false.`` | ``.true.``

      +----------+----------------+
      | Value    | Description    |
      +==========+================+
      | .false.  | do not enable  |
      +----------+----------------+
      | .true.   | enable         |
      +----------+----------------+

``output_dir``
   Specifies the output directory.

.. COMMENT: Is this required if "separate_output=.true."?

``restart_frequency_s``
   Specifies the restart frequency (in seconds) for the UFS land model.

``restart_simulation``
   Specifies whether to enable the restart simulation. Valid values: ``.false.`` | ``.true.``

      +----------+----------------+
      | Value    | Description    |
      +==========+================+
      | .false.  | do not enable  |
      +----------+----------------+
      | .true.   | enable         |
      +----------+----------------+

``restart_date``
   Specifies the restart date. The form is ``YYYY-MM-DD HH:MM:SS``, where 
   YYYY is a 4-digit year, MM is a valid 2-digit month, DD is a valid 2-digit day, 
   HH is a valid 2-digit hour, MM is a valid 2-digit minute, and SS is a valid 2-digit second.

``restart_dir``
   Specifies the restart directory.

``timestep_seconds``
   Specifies the timestep in seconds.

``simulation_start``
   Specifies the simulation start time. The form is ``YYYY-MM-DD HH:MM:SS``, where 
   YYYY is a 4-digit year, MM is a valid 2-digit month, DD is a valid 2-digit day, 
   HH is a valid 2-digit hour, MM is a valid 2-digit minute, and SS is a valid 2-digit second.

``simulation_end``
   Specifies the simulation end time. The form is ``YYYY-MM-DD HH:MM:SS``, where 
   YYYY is a 4-digit year, MM is a valid 2-digit month, DD is a valid 2-digit day, 
   HH is a valid 2-digit hour, MM is a valid 2-digit minute, and SS is a valid 2-digit second.

``run_days``
   Specifies the number of days to run.

``run_hours``
   Specifies the number of hours to run.

``run_minutes``
   Specifies the number of minutes to run.

``run_seconds``
   Specifies the number of seconds to run.

``run_timesteps``
   Specifies the number of timesteps to run.

Land Model Options
^^^^^^^^^^^^^^^^^^^^^

``land_model``
   Specifies which land surface model to use. Valid values: ``1`` | ``2``

      +--------+-------------+
      | Value  | Description |
      +========+=============+
      | 1      | Noah        |
      +--------+-------------+
      | 2      | Noah-MP     |
      +--------+-------------+

Structure-Related Parameters
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

``num_soil_levels``
   Specifies the number of soil levels.

``forcing_height``
   Specifies the forcing height in meters.

Soil Setup Parameters
^^^^^^^^^^^^^^^^^^^^^^^

``soil_level_thickness``
   Specifies the thickness (in meters) of each of the soil layers (top layer to bottom layer).

``soil_level_nodes``
   Specifies the soil level centroids from the surface (in meters).

Noah-MP.4.0.1 Options
^^^^^^^^^^^^^^^^^^^^^^^^

``dynamic_vegetation_option``
   Specifies the dynamic vegetation model option. Valid values: ``1`` | ``2`` | ``3`` | ``4`` | ``5`` | ``6`` | ``7`` | ``8`` | ``9`` | ``10``

      +-------+------------------------------------------------------------+
      | Value | Description                                                |
      +=======+============================================================+
      | 1     | off (use table LAI; use FVEG=SHDFAC from input)            |
      +-------+------------------------------------------------------------+
      | 2     | on (dynamic vegetation; must use Ball-Berry canopy option) |
      +-------+------------------------------------------------------------+
      | 3     | off (use table LAI; calculate FVEG)                        |
      +-------+------------------------------------------------------------+
      | 4     | off (use table LAI; use maximum vegetation fraction)       |
      +-------+------------------------------------------------------------+
      | 5     | on (use maximum vegetation fraction)                       |
      +-------+------------------------------------------------------------+
      | 6     | on (use FVEG = SHDFAC from input)                          |
      +-------+------------------------------------------------------------+
      | 7     | off (use input LAI; use FVEG = SHDFAC from input)          |
      +-------+------------------------------------------------------------+
      | 8     | off (use input LAI; calculate FVEG)                        |
      +-------+------------------------------------------------------------+
      | 9     | off (use input LAI; use maximum vegetation fraction)       |
      +-------+------------------------------------------------------------+
      | 10    | crop model on (use maximum vegetation fraction)            |
      +-------+------------------------------------------------------------+

``LAI``
   Routines for handling Leaf/Stem area index data products

``FVEG``
   Green vegetation fraction [0.0-1.0]

``SHDFAC``
   Greenness vegetation (shaded) fraction

``canopy_stomatal_resistance_option`` 
   Specifies the canopy stomatal resistance option. Valid values: ``1`` | ``2``

      +--------+--------------+
      | Value  | Description  |
      +========+==============+
      | 1      | Ball-Berry   |
      +--------+--------------+
      | 2      | Jarvis       |
      +--------+--------------+
      
``soil_wetness_option`` 
   Specifies the soil moisture factor for the stomatal resistance option. Valid values: ``1`` | ``2`` | ``3``

      +--------+-------------------------+
      | Value  | Description             |
      +========+=========================+
      | 1      | Noah (soil moisture)    |
      +--------+-------------------------+
      | 2      | CLM (matric potential)  |
      +--------+-------------------------+
      | 3      | SSiB (matric potential) |
      +--------+-------------------------+

``runoff_option`` 
   Specifies the runoff option. Valid values: ``1`` | ``2`` | ``3`` | ``4`` | ``5``

      +--------+-----------------------------------------------------------------------+
      | Value  | Description                                                           |
      +========+=======================================================================+
      | 1      | SIMGM: TOPMODEL with groundwater (:cite:t:`NiuEtAl2007`)              |
      +--------+-----------------------------------------------------------------------+
      | 2      | SIMTOP: TOPMODEL with an equilibrium water table                      |
      |        | (:cite:t:`NiuEtAl2005`)                                               |
      +--------+-----------------------------------------------------------------------+
      | 3      | Noah original surface and subsurface runoff (free drainage)           |
      |        | (:cite:t:`SchaakeEtAl1996`)                                           |
      +--------+-----------------------------------------------------------------------+
      | 4      | BATS surface and subsurface runoff (free drainage)                    |
      +--------+-----------------------------------------------------------------------+
      | 5      | Miguez-Macho&Fan groundwater scheme (:cite:t:`Miguez-MachoEtAl2007`;  |
      |        | :cite:t:`FanEtAl2007`)                                                |
      +--------+-----------------------------------------------------------------------+

``surface_exchange_option``
   Specifies the surface layer drag coefficient option. Valid values: ``1`` | ``2``

      +--------+---------------------------+
      | Value  | Description               |
      +========+===========================+
      | 1      | Monin-Obukhov             |
      +--------+---------------------------+
      | 2      | original Noah (Chen 1997) |
      +--------+---------------------------+

``supercooled_soilwater_option``
   Specifies the supercooled liquid water option. Valid values: ``1`` | ``2``

      +--------+---------------------------------------------+
      | Value  | Description                                 |
      +========+=============================================+
      | 1      | no iteration (:cite:t:`Niu&Yang2006`)       |
      +--------+---------------------------------------------+
      | 2      | Koren's iteration (:cite:t:`KorenEtAl1999`) |
      +--------+---------------------------------------------+

``frozen_soil_adjust_option``
   Specifies the frozen soil permeability option. Valid values: ``1`` | ``2``

      +--------+-------------------------------------------------------------+
      | Value  | Description                                                 |
      +========+=============================================================+
      | 1      | linear effects, more permeable (:cite:t:`Niu&Yang2006`)     |
      +--------+-------------------------------------------------------------+
      | 2      | nonlinear effects, less permeable (:cite:t:`KorenEtAl1999`) |
      +--------+-------------------------------------------------------------+

``radiative_transfer_option``
   Specifies the radiation transfer option. Valid values: ``1`` | ``2`` | ``3``

      +--------+--------------------------------------------------------------------+
      | Value  | Description                                                        |
      +========+====================================================================+
      | 1      | modified two-stream (gap = F(solar angle, 3D structure...)<1-FVEG) |
      +--------+--------------------------------------------------------------------+
      | 2      | two-stream applied to grid-cell (gap = 0)                          |
      +--------+--------------------------------------------------------------------+
      | 3      | two-stream applied to a vegetated fraction (gap=1-FVEG)            |
      +--------+--------------------------------------------------------------------+

``snow_albedo_option``
   Specifies the snow surface albedo option. Valid values: ``1`` | ``2``

      +--------+--------------+
      | Value  | Description  |
      +========+==============+
      | 1      | BATS         |
      +--------+--------------+
      | 2      | CLASS        |
      +--------+--------------+

``precip_partition_option``
   Specifies the option for partitioning precipitation into rainfall and snowfall. Valid values: ``1`` | ``2`` | ``3`` | ``4``

      +--------+-----------------------------+
      | Value  | Description                 |
      +========+=============================+
      | 1      | :cite:t:`Jordan1991`        |
      +--------+-----------------------------+
      | 2      | BATS: when SFCTMP<TFRZ+2.2  |
      +--------+-----------------------------+
      | 3      | Noah: when SFCTMP<TFRZ      |
      +--------+-----------------------------+
      | 4      | Use WRF microphysics output |
      +--------+-----------------------------+

``SFCTMP``
   Surface air temperature

``TFRZ``
   Freezing/melting point (K)

``soil_temp_lower_bdy_option``
   Specifies the lower boundary condition of soil temperature option. Valid values: ``1`` | ``2``

      +--------+---------------------------------------------------------+
      | Value  | Description                                             |
      +========+=========================================================+
      | 1      | zero heat flux from the bottom (ZBOT and TBOT not used) |
      +--------+---------------------------------------------------------+
      | 2      | TBOT at ZBOT (8m) read from a file (original Noah)      |
      +--------+---------------------------------------------------------+

``TBOT``
   Lower boundary soil temperature [K]

``ZBOT``
   Depth[m] of lower boundary soil temperature (TBOT)

``soil_temp_time_scheme_option``
   Specifies the snow and soil temperature time scheme. Valid values: ``1`` | ``2`` | ``3``

      +--------+------------------------------------------------------------------------+
      | Value  | Description                                                            |
      +========+========================================================================+
      | 1      | semi-implicit; flux top boundary condition                             |
      +--------+------------------------------------------------------------------------+
      | 2      | fully implicit (original Noah); temperature top boundary condition     |
      +--------+------------------------------------------------------------------------+
      | 3      | same as 1, but FSNO for TS calculation (generally improves snow; v3.7) |
      +--------+------------------------------------------------------------------------+

``FSNO``
   Fraction of surface covered with snow

``TS``
   Surface temperature

``surface_evap_resistance_option``
   Specifies the surface evaporation resistance option. Valid values: ``1`` | ``2`` | ``3`` | ``4``

      +----------------+-----------------------------------------------------+
      | Value          | Description                                         |
      +================+=====================================================+
      | 1              | :cite:t:`Sakaguchi&Zeng2009`                        |
      +----------------+-----------------------------------------------------+
      | 2              | :cite:t:`SellersEtAl1992`                           |
      +----------------+-----------------------------------------------------+
      | 3              | adjusted Sellers to decrease RSURF for wet soil     |
      +----------------+-----------------------------------------------------+
      | 4              | option 1 for non-snow; rsurf = rsurf_snow for snow  |
      +----------------+-----------------------------------------------------+

``rsurf``
   Ground surface resistance (s/m)

``glacier_option``
   Specifies the glacier model option. Valid values: ``1`` | ``2``

      +--------+------------------------------------------------+
      | Value  | Description                                    |
      +========+================================================+
      | 1      | include phase change of ice                    |
      +--------+------------------------------------------------+
      | 2      | simple (ice treatment more like original Noah) |
      +--------+------------------------------------------------+

Forcing Parameters
^^^^^^^^^^^^^^^^^^^^^

``forcing_timestep_seconds``
   Specifies the timestep of forcing in seconds.

``forcing_type``
   Specifies the forcing type option. Valid values: ``single-point``

      +----------------+-----------------------------------------------------+
      | Value          | Description                                         |
      +================+=====================================================+
      | single-point   |                                                     |
      +----------------+-----------------------------------------------------+
      |                |                                                     |
      +----------------+-----------------------------------------------------+
      |                |                                                     |
      +----------------+-----------------------------------------------------+
      |                |                                                     |
      +----------------+-----------------------------------------------------+

``forcing_filename``
   Specifies the forcing file name. 
   Valid values: ``C96__GDAS_forcing`` | ``C96_GEFS_forcing`` | ``C96_GSWP3_forcing``

      +-------------------+-----------------------------------------------------+
      | Value             | Description                                         |
      +===================+=====================================================+
      | C96__GDAS_forcing |                                                     |
      +-------------------+-----------------------------------------------------+
      | C96_GEFS_forcing  |                                                     |
      +-------------------+-----------------------------------------------------+
      | C96_GSWP3_forcing |                                                     |
      +-------------------+-----------------------------------------------------+

.. COMMENT: Are these variable names correct? They were split over two lines, 
   and it's not clear whether underscores should be added or removed in some cases...

``forcing_interp_solar``
   Specifies the interpolation option for solar radiation. Valid values: ``linear``

      +------------+-----------------------------------------------------+
      | Value      | Description                                         |
      +============+=====================================================+
      | linear     |                                                     |
      +------------+-----------------------------------------------------+
      |            |                                                     |
      +------------+-----------------------------------------------------+
      |            |                                                     |
      +------------+-----------------------------------------------------+
      |            |                                                     |
      +------------+-----------------------------------------------------+

``forcing_name_precipitation``
   Specifies the name of forcing precipitation.

``forcing_name_temperature``
   Specifies the name of forcing temperature.

``forcing_name_specific_humidity``
   Specifies the name of forcing specific-humidity.

``forcing_name_wind_speed``
   Specifies the name of forcing wind speed.

``forcing_name_pressure``
   Specifies the name of forcing surface pressure.

``forcing_name_sw_radiation``
   Specifies the name of forcing shortwave radiation.

``forcing_name_lw_radiation``
   Specifies the name of forcing longwave radiation.

.. COMMENT: Are these "forcing_name_*" variables all *file* names? 
   Or are there specific options that users should be choosing from...?
   I'm not clear on what these variables are naming. 

Example of a ``ufs-land.namelist.noahmp`` Entry
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: console
   
   &run_setup

   static_file = “/*/filename.nc”
   init_file = “/*/filename.nc”
   forcing_dir = "/ /"
   separate_output = .true.
   output_dir = "./noahmp_output/"
   restart_frequency_s = 86400
   restart_simulation = .true.
   restart_date = "XXYYYY-XXMM-XXDD XXHH:00:00"
   restart_dir = "./restarts/vector/"
   timestep_seconds = 3600

   &simulation start and end
   simulation_start = "2000-01-01 00:00:00" 
   simulation_end = "1999-01-01 06:00:00" 

   run_days = 1 
   run_hours = 0 
   run_minutes = 0 
   run_seconds = 0 
   run_timesteps = 0 

   begloc = 1
   endloc = 18360

   &land_model_option
   land_model = 2 

   &structure
   num_soil_levels = 4 
   forcing_height = 6 

   &soil_setup
   soil_level_thickness = 0.10, 0.30, 0.60, 1.00 
   soil_level_nodes = 0.05, 0.25, 0.70, 1.50 

   &noahmp_options
   dynamic_vegetation_option = 4
   canopy_stomatal_resistance_option = 2
   soil_wetness_option = 1
   runoff_option = 1
   surface_exchange_option = 3
   supercooled_soilwater_option = 1
   frozen_soil_adjust_option = 1
   radiative_transfer_option = 3
   snow_albedo_option = 2
   precip_partition_option = 1
   soil_temp_lower_bdy_option = 2
   soil_temp_time_scheme_option = 3
   thermal_roughness_scheme_option = 2
   surface_evap_resistance_option = 1
   glacier_option = 1

   &forcing
   forcing_timestep_seconds = 10800
   forcing_type = "gswp3"
   forcing_filename = "C96_GEFS_forcing\_"
   forcing_interp_solar = "gswp3_zenith" 
   forcing_time_solar = "gswp3_average" 
   forcing_name_precipitation = "precipitationXXMEM"
   forcing_name_temperature = "temperatureXXMEM"
   forcing_name_specific_humidity = "specific_humidityXXMEM"
   forcing_name_wind_speed = "wind_speedXXMEM"
   forcing_name_pressure = "surface_pressureXXMEM"
   forcing_name_sw_radiation = "solar_radiationXXMEM"
   forcing_name_lw_radiation = "longwave_radiationXXMEM"


.. _VectorTileConverter:

Vector-to-Tile Converter
============================

The Vector-to-Tile Converter is used for mapping between the vector format
used by the Noah-MP offline driver, and the tile format used by the UFS
atmospheric model. This is currently used to prepare input tile files
for JEDI. Note that these files include only those fields required by
JEDI, rather than the full restart.

Building and Running the Vector-to-Tile Converter
-----------------------------------------------------

#. Clone the UFS land model from GitHub:

   .. code-block:: console
      
      git clone --recurse-submodules https://github.com/NOAA-PSL/land-vector2tile

#. Navigate to the land vector to tile:

   .. code-block:: console

      cd land-vector2tile

#. Configure

   .. code-block:: console

      ./configure

#. To compile:

   .. code-block:: console
      
      make

#. To run:

   .. code-block:: console

      Vector2tile_converter.exe namelist.vector2tile

.. _V2TInputFiles:

Input File
---------------------

The input files containing grid information are listed in :numref:`Table %s <GridInputFiles>`:


.. _GridInputFiles:

.. table:: Input Files Containing Grid Information

   +-----------------------------+--------------------------------------------------------------------------+
   | Filename                    | Description                                                              |
   +=============================+==========================================================================+
   | Cxx_grid.tile[1-6].nc       | Cxx grid information for tiles 1-6, where ``xx`` is the grid number.     |
   +-----------------------------+--------------------------------------------------------------------------+
   | Cxx_oro_data.tile[1-6].nc   | Model terrain (topographic/orographic information) for grid tiles 1-6.   |
   +-----------------------------+--------------------------------------------------------------------------+
   | oro_Cxx.mx100.tile[1-6].nc  |                                                                          |
   +-----------------------------+--------------------------------------------------------------------------+

Configuration File
---------------------

This section describes the options in the ``namelist.vector2tile`` file.

Run Setup Parameters
^^^^^^^^^^^^^^^^^^^^^^

``direction``
   Specifies the conversion option. Valid values: ``vector2tile`` | ``tile2vector`` | ``lndp2tile`` | ``lndp2vector``

      +--------------+---------------------------------------------+
      | Value        | Description                                 |
      +==============+=============================================+
      | vector2tile  | vector-to-tile conversion for restart file  |
      +--------------+---------------------------------------------+
      | tile2vector  | tile-to-vector conversion for restart file  |
      +--------------+---------------------------------------------+
      | lndp2tile    | land perturbation to tile                   |
      +--------------+---------------------------------------------+
      | lndp2vector  | land perturbation to vector                 |
      +--------------+---------------------------------------------+

Tile-Related Parameters for Restart/Perturbation Conversion
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Parameters in this section include the FV3 resolution and path to orographic files 
for restart/perturbation conversion. 

.. COMMENT: I took this description above from the original section title, but it seems 
   like it all has more to do with tiles than orographic files... 
   Could use a little clarification.

``tile_size``
   Specifies the size of tile

.. COMMENT: What are the units (# grid/tile cells?)? Are there set tile sizes? Or can it be any number?

``tile_path``
   Specifies the path of tile location

``tile_fstub``
   Specifies the file stub for orography files in ``tile_path``. The file stub will be named ``oro_C${RES}`` for atmosphere-only and ``oro_C{RES}.mx100`` for atmosphere and ocean.

Parameters for Restart Conversion
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

These parameters apply *only* to restart conversion.

``static_filename``
   Specifies the path for static file.

``vector_restart_path``
   Specifies the location of vector restart file, vector-to-tile direction.

``tile_restart_path``
   Specifies the location of tile restart file, tile-to-vector direction.

``output_path``
   Specifies the path for converted files. If this is same
   as tile/vector path, the files may be overwritten.

Perturbation Mapping Parameters
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

These parameters are *only* relevant for perturbation mapping. 

``lndp_layout``
   Specifies the layout options. Valid values: ``1x4`` | ``4x1`` | ``2x2``

      +-------+-----------------------------------------------------+
      | Value | Description                                         |
      +=======+=====================================================+
      | 1x4   |                                                     |
      +-------+-----------------------------------------------------+
      | 4x1   |                                                     |
      +-------+-----------------------------------------------------+
      | 2x2   |                                                     |
      +-------+-----------------------------------------------------+


``lndp_input_file``
   Specifies the path for input file.

``output files``
   Specifies the path for output file

``lndp_var_list``
   Specifies the land perturbation variable options. Valid values: ``vgf`` | ``smc``

      +-------+-----------------------------------------------------+
      | Value | Description                                         |
      +=======+=====================================================+
      | vgf   |                                                     |
      +-------+-----------------------------------------------------+
      | smc   |                                                     |
      +-------+-----------------------------------------------------+
      |       |                                                     |
      +-------+-----------------------------------------------------+


Example of a ``namelist.vector2tile`` Entry
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: console

   &run_setup

   direction = "vector2tile"

   &FV3 resolution and path to oro files for restart/perturbation
   conversion

   tile_size = 96
   tile_path ="/ /"
   tile_fstub = "oro_C96.mx100"

   !------------------- only restart conversion -------------------

   ! Time stamp for conversion for restart conversion
   restart_date = "2019-09-30 23:00:00"

   ! Path for static file
   static_filename="/*/filename.nc "

   ! Location of vector restart file (vector2tile direction)
   vector_restart_path ="/ /"

   ! Location of tile restart files (tile2vector direction)
   tile_restart_path ="/ /"

   output_path ="/ /"

   !------------------- only perturbation mapping -------------------
   lndp_layout = "1x4"

   ! input files
   lndp_input_file ="/*/filename.nc "

   ! output files
   lndp_output_file = "./output.nc"

   ! land perturbation variable list
   lndp_var_list='vgf','smc'
