.. _Model:

********************************
Noah-MP Land Surface Model
********************************

This chapter provides practical information on input files and parameters for the Noah-MP Land Surface Model (LSM) and its Vector-to-Tile Converter component.
For background information on the Noah-MP Land Surface Model (LSM), see :numref:`Section %s <NoahMP>` of the Introduction. 

.. _InputFiles:

Input Files 
**************

The UFS land model requires multiple input files to run: static datasets
(fix files containing climatological information, terrain, and land use
data), initial conditions and forcing files, and model configuration
files (such as namelists). Users may reference the `Community Noah-MP User's
Guide <https://www.jsg.utexas.edu/noah-mp/files/Users_Guide_v0.pdf>`__
for a detailed technical description of certain elements of the Noah-MP model.

There are several important files used to specify model parameters: 
the static file (``ufs-land_C96_static_fields.nc``), 
the initial conditions file (``ufs-land_C96_init_*.nc``), 
and the model configuration file (``ufs-land.namelist.noahmp``). 
These files and their parameters are described in the following subsections. 
They are publicly available via the `Land DA Data Bucket <https://noaa-ufs-land-da-pds.s3.amazonaws.com/index.html>`__. 
Users can download the data and untar the file via the command line, replacing 
``{YEAR}`` with the year for the desired data. Release data is currently 
available for 2016 and 2020:

.. _TarFile:

.. code-block:: console
   
   wget https://noaa-ufs-land-da-pds.s3.amazonaws.com/current_land_da_release_data/landda-input-data-{YEAR}.tar.gz
   tar xvfz landda-input-data-{YEAR}.tar.gz

Static File (``ufs-land_C96_static_fields.nc``)
=================================================

The static file includes specific information on location, time, soil layers, and fixed (invariant) experiment parameters that are required for Noah-MP to run. The data must be provided in :term:`netCDF` format.

The static file is available in the ``inputs`` data directory (downloaded :ref:`above <InputFiles>`) at the following path:

.. code-block:: 

   inputs/forcing/<source>/static/ufs-land_C96_static_fields.nc

where ``<source>`` is either ``gdas`` or ``era5``. 

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
   | cube_tile                 | FV3 tile where the grid is located       |
   +---------------------------+------------------------------------------+
   | cube_i                    | i-location in the FV3 tile where the     |
   |                           | grid is located                          |
   +---------------------------+------------------------------------------+
   | cube_j                    | j-location in the FV3 tile where the     |
   |                           | grid is located                          |
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

Initial Conditions File (``ufs-land_C96_init_*.nc``)
=================================================================

The offline Land DA System currently only supports snow DA. 
The initial conditions file includes the initial state variables that are required for the UFS land snow DA to begin a cycling run. The data must be provided in :term:`netCDF` format.

The initial conditions file is available in the ``inputs`` data directory (downloaded :ref:`above <TarFile>`) at the following path:

.. code-block:: 

   inputs/forcing/GDAS/init/ufs-land_C96_init_fields_1hr.nc
   inputs/forcing/ERA5/init/ufs-land_C96_init_2010-12-31_23-00-00.nc

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
==========================================================

The UFS land model uses a series of template files combined with 
user-selected settings to create required namelists and parameter
files needed by the UFS Land DA workflow. This section describes the
options in the ``ufs-land.namelist.noahmp`` file, which is generated 
from the ``template.ufs-noahMP.namelist.*`` file. 

.. note:: 

   Any default values indicated are the defaults set in the ``template.ufs-noahMP.namelist.*`` files. 

Run Setup Parameters
----------------------

``static_file``
   Specifies the path to the UFS land static file. 

``init_file``
   Specifies the path to the UFS land initial condition file. 

``forcing_dir``
   Specifies the path to the UFS land forcing directory where atmospheric forcing files are located. 

``separate_output``
   Specifies whether to enable separate output files for each output time. Valid values: ``.false.`` | ``.true.``

      +----------+---------------------------------------+
      | Value    | Description                           |
      +==========+=======================================+
      | .false.  | do not enable (should only be used    |
      |          | for single point or short simulations)|
      +----------+---------------------------------------+
      | .true.   | enable                                |
      +----------+---------------------------------------+

``output_dir``
   Specifies the output directory where output files will be saved. If ``separate_output=.true.``, but no ``output_dir`` is specified, it will default to the directory where the executable is run.

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
   Specifies the land model timestep in seconds.

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
---------------------

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
-------------------------------

``num_soil_levels``
   Specifies the number of soil levels.

``forcing_height``
   Specifies the forcing height in meters.

Soil Setup Parameters
-----------------------

``soil_level_thickness``
   Specifies the thickness (in meters) of each of the soil layers (top layer to bottom layer).

``soil_level_nodes``
   Specifies the soil level centroids from the surface (in meters).

Noah-MP Options
------------------------

``dynamic_vegetation_option``: (Default: ``4``)
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

``canopy_stomatal_resistance_option``: (Default: ``2``)
   Specifies the canopy stomatal resistance option. Valid values: ``1`` | ``2``

      +--------+--------------+
      | Value  | Description  |
      +========+==============+
      | 1      | Ball-Berry   |
      +--------+--------------+
      | 2      | Jarvis       |
      +--------+--------------+
      
``soil_wetness_option``: (Default: ``1``)
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

``runoff_option``: (Default: ``1``)
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

``surface_exchange_option``: (Default: ``3``)
   Specifies the surface layer drag coefficient option. Valid values: ``1`` | ``2``

      +--------+---------------------------+
      | Value  | Description               |
      +========+===========================+
      | 1      | Monin-Obukhov             |
      +--------+---------------------------+
      | 2      | original Noah (Chen 1997) |
      +--------+---------------------------+

``supercooled_soilwater_option``: (Default: ``1``)
   Specifies the supercooled liquid water option. Valid values: ``1`` | ``2``

      +--------+---------------------------------------------+
      | Value  | Description                                 |
      +========+=============================================+
      | 1      | no iteration (:cite:t:`Niu&Yang2006`)       |
      +--------+---------------------------------------------+
      | 2      | Koren's iteration (:cite:t:`KorenEtAl1999`) |
      +--------+---------------------------------------------+

``frozen_soil_adjust_option``: (Default: ``1``)
   Specifies the frozen soil permeability option. Valid values: ``1`` | ``2``

      +--------+-------------------------------------------------------------+
      | Value  | Description                                                 |
      +========+=============================================================+
      | 1      | linear effects, more permeable (:cite:t:`Niu&Yang2006`)     |
      +--------+-------------------------------------------------------------+
      | 2      | nonlinear effects, less permeable (:cite:t:`KorenEtAl1999`) |
      +--------+-------------------------------------------------------------+

``radiative_transfer_option``: (Default: ``3``)
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

``snow_albedo_option``: (Default: ``2``)
   Specifies the snow surface albedo option. Valid values: ``1`` | ``2``

      +--------+--------------+
      | Value  | Description  |
      +========+==============+
      | 1      | BATS         |
      +--------+--------------+
      | 2      | CLASS        |
      +--------+--------------+

``precip_partition_option``: (Default: ``1``)
   Specifies the option for partitioning precipitation into rainfall and snowfall. Valid values: ``1`` | ``2`` | ``3`` | ``4``

      +--------+-----------------------------+
      | Value  | Description                 |
      +========+=============================+
      | 1      | :cite:t:`Jordan1991` (1991) |
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

``soil_temp_lower_bdy_option``: (Default: ``2``)
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

``soil_temp_time_scheme_option``: (Default: ``3``)
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

``thermal_roughness_scheme_option``: (Default: ``2``)
   Specifies the method/scheme used to calculate the thermal roughness length. Valid values: ``1`` | ``2`` | ``3`` | ``4``

      +--------+--------------------------------------------------------------------+
      | Value  | Description                                                        |
      +========+====================================================================+
      | 1      | z0h=z, thermal roughness length = momentum roughness length        |
      +--------+--------------------------------------------------------------------+
      | 2      | czil, use canopy height method based on (:cite:t:`Chen&Zhang2009`) |
      +--------+--------------------------------------------------------------------+
      | 3      | European Center method                                             |
      +--------+--------------------------------------------------------------------+
      | 4      | kb inverse method                                                  |
      +--------+--------------------------------------------------------------------+

``surface_evap_resistance_option``: (Default: ``1``)
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

``glacier_option``: (Default: ``1``)
   Specifies the glacier model option. Valid values: ``1`` | ``2``

      +--------+------------------------------------------------+
      | Value  | Description                                    |
      +========+================================================+
      | 1      | include phase change of ice                    |
      +--------+------------------------------------------------+
      | 2      | simple (ice treatment more like original Noah) |
      +--------+------------------------------------------------+

Forcing Parameters
---------------------

``forcing_timestep_seconds``: (Default: ``3600``)
   Specifies the forcing timestep in seconds.

``forcing_type``
   Specifies the forcing type option, which describes the frequency and length of forcing in each forcing file. Valid values: ``single-point`` | ``gswp3`` | ``gdas``

      +----------------+-----------------------------------------------------+
      | Value          | Description                                         |
      +================+=====================================================+
      | single-point   | All forcing times are in one file                   |
      +----------------+-----------------------------------------------------+
      | gswp3          | three-hourly forcing stored in monthly files        |
      +----------------+-----------------------------------------------------+
      | gdas           | hourly forcing stored in daily files                |
      +----------------+-----------------------------------------------------+

      .. note:: 

         There is no separate ``era5`` format. It is the same as the ``gdas`` format, 
         so users should select ``gdas`` for this parameter when using ``era5`` forcing. 

``forcing_filename``
   Specifies the forcing file name prefix. A date will be appended to this prefix. For example: ``C96_ERA5_forcing_2020-10-01.nc``. The prefix merely indicates which grid (``C96``) and source (i.e., GDAS, GEFS) will be used. 
   Common values include: ``C96_GDAS_forcing_`` | ``C96_ERA5_forcing_`` | ``C96_GEFS_forcing_`` | ``C96_GSWP3_forcing_``

      +-----------------------+--------------------------------------------+
      | Value                 | Description                                |
      +=======================+============================================+
      | ``C96_GDAS_forcing_`` | GDAS forcing data for a C96 grid           |
      +-----------------------+--------------------------------------------+
      | ``C96_ERA5_forcing_`` | ERA5 forcing data for a C96 grid           |
      +-----------------------+--------------------------------------------+
      | ``C96_GEFS_forcing_`` | GEFS forcing data for a C96 grid           |
      +-----------------------+--------------------------------------------+
      | ``C96_GSWP3_forcing_``| GSWP3 forcing data for a C96 grid          |
      +-----------------------+--------------------------------------------+

``forcing_interp_solar``
   Specifies the interpolation option for solar radiation. Valid values: ``linear`` | ``gswp3_zenith``

      +--------------+-------------------------------------------------------+
      | Value        | Description                                           |
      +==============+=======================================================+
      | linear       | Performs a linear interpolation between forcing times |
      +--------------+-------------------------------------------------------+
      | gswp3_zenith | Performs a cosine zenith angle interpolation between  |
      |              | forcing times                                         |
      +--------------+-------------------------------------------------------+

``forcing_time_solar``
   Valid values include: ``"instantaneous"`` | ``"gswp3_average"``

``forcing_name_precipitation``
   Specifies the variable name of forcing precipitation. Valid values include: ``"precipitation_conserve"`` | ``"precipitation_bilinear"``

``forcing_name_temperature``(Default: ``"temperature"``)
   Specifies the variable name of forcing temperature.

``forcing_name_specific_humidity``: (Default: ``"specific_humidity"``)
   Specifies the variable name of forcing specific-humidity.

``forcing_name_wind_speed``: (Default: ``"wind_speed"``)
   Specifies the variable name of forcing wind speed.

``forcing_name_pressure``: (Default: ``"surface_pressure"``)
   Specifies the variable name of forcing surface pressure.

``forcing_name_sw_radiation``: (Default: ``"solar_radiation"``)
   Specifies the variable name of forcing shortwave radiation.

``forcing_name_lw_radiation``: (Default: ``"longwave_radiation"``)
   Specifies the variable name of forcing longwave radiation.

Example Namelist Entry
--------------------------------------------------

The ``ufs-land.namelist.noahmp`` file should be similar to the following example, which comes from the ``template.ufs-noahMP.namelist.gdas`` file. 

.. code-block:: console
   
   &run_setup

      static_file      = "/LANDDA_INPUTS/forcing/gdas/static/ufs-land_C96_static_fields.nc"
      init_file        = "/LANDDA_INPUTS/forcing/gdas/init/ufs-land_C96_init_fields_1hr.nc"
      forcing_dir      = "/LANDDA_INPUTS/forcing/gdas/gdas/forcing"
      
      separate_output = .false.
      output_dir       = "./"

      restart_frequency_s = XXFREQ
      restart_simulation  = .true.
      restart_date        = "XXYYYY-XXMM-XXDD XXHH:00:00"
      restart_dir         = "./"

      timestep_seconds = 3600

   ! simulation_start is required
   ! either set simulation_end or run_* or run_timesteps, priority
   !   1. simulation_end 2. run_[days/hours/minutes/seconds] 3. run_timesteps

      simulation_start = "2000-01-01 00:00:00"   ! start date [yyyy-mm-dd hh:mm:ss]
      ! simulation_end   = "1999-01-01 06:00:00"   !   end date [yyyy-mm-dd hh:mm:ss]

      run_days         = XXRDD   ! number of days to run
      run_hours        = XXRHH   ! number of hours to run
      run_minutes      = 0       ! number of minutes to run
      run_seconds      = 0       ! number of seconds to run
      
      run_timesteps    = 0       ! number of timesteps to run
      
      location_start   = 1
      location_end     = 18360

   /

   &land_model_option
      land_model        = 2   ! choose land model: 1=noah, 2=noahmp
   /

   &structure
      num_soil_levels   = 4     ! number of soil levels
      forcing_height    = 6     ! forcing height [m]
   /

   &soil_setup
      soil_level_thickness   =  0.10,    0.30,    0.60,    1.00      ! soil level thicknesses [m]
      soil_level_nodes       =  0.05,    0.25,    0.70,    1.50      ! soil level centroids from surface [m]
   /

   &noahmp_options
      dynamic_vegetation_option         = 4
      canopy_stomatal_resistance_option = 2
      soil_wetness_option               = 1
      runoff_option                     = 1
      surface_exchange_option           = 3
      supercooled_soilwater_option      = 1
      frozen_soil_adjust_option         = 1
      radiative_transfer_option         = 3
      snow_albedo_option                = 2
      precip_partition_option           = 1
      soil_temp_lower_bdy_option        = 2
      soil_temp_time_scheme_option      = 3
      thermal_roughness_scheme_option   = 2
      surface_evap_resistance_option    = 1
      glacier_option                    = 1
   /

   &forcing
      forcing_timestep_seconds       = 3600
      forcing_type                   = "gdas"
      forcing_filename               = "C96_GDAS_forcing_"
      forcing_interp_solar           = "linear"  ! gswp3_zenith or linear
      forcing_time_solar             = "instantaneous"  ! gswp3_average or instantaneous
      forcing_name_precipitation     = "precipitation_conserve"
      forcing_name_temperature       = "temperature"
      forcing_name_specific_humidity = "specific_humidity"
      forcing_name_wind_speed        = "wind_speed"
      forcing_name_pressure          = "surface_pressure"
      forcing_name_sw_radiation      = "solar_radiation"
      forcing_name_lw_radiation      = "longwave_radiation"
   /


.. _VectorTileConverter:

Vector-to-Tile Converter
***************************

The Vector-to-Tile Converter is used for mapping between the vector format
used by the Noah-MP offline driver and the tile format used by the UFS
atmospheric model. This converter is currently used to prepare input tile files
for JEDI. Note that these files include only those fields required by
JEDI, rather than the full restart.

.. _V2TInputFiles:

Input File
=============

The input files containing grid information are listed in :numref:`Table %s <GridInputFiles>`:

.. _GridInputFiles:

.. table:: Input Files Containing Grid Information

   +-----------------------------+--------------------------------------------------------------------------+
   | Filename                    | Description                                                              |
   +=============================+==========================================================================+
   | Cxx_grid.tile[1-6].nc       | Cxx grid information for tiles 1-6, where ``xx`` is the grid resolution. |
   +-----------------------------+--------------------------------------------------------------------------+
   | Cxx_oro_data.tile[1-6].nc / | Orography files that contain grid and land mask information. Cxx refers  |
   |                             | to the atmospheric resolution, and mx100 refers to the ocean resolution  |
   | oro_Cxx.mx100.tile[1-6].nc  | (100=1º). Both file names refer to the same file; there are symbolic     |
   |                             | links between them.                                                      |
   +-----------------------------+--------------------------------------------------------------------------+
   
Configuration File
======================

This section describes the options in the ``namelist.vector2tile`` file.

Run Setup Parameters
----------------------

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

FV3 Tile-Related Parameters for Restart/Perturbation Conversion
---------------------------------------------------------------

Parameters in this section include the FV3 resolution and path to orographic files 
for restart/perturbation conversion. 

``tile_size``
   Specifies the size (horizontal resolution) of the FV3 tile. Valid values: ``96``. 
   
   .. note:: 
      
      * The ``C96`` grid files correspond to approximately 1º latitude/longitude. 
      * Additional resolutions (e.g., ``192``, ``384``, ``768``) are under development. 

``tile_path``
   Specifies the path to the orographic tile files.

``tile_fstub``
   Specifies the name (file stub) of orographic tile files. The file stub will be named ``oro_C${RES}`` for atmosphere-only and ``oro_C{RES}.mx100`` for atmosphere and ocean. 

Parameters for Restart Conversion
------------------------------------

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
----------------------------------

These parameters are *only* relevant for perturbation mapping in ensembles. 
Support for ensembles is *not* provided for the Land DA v1.0.0 release. 

``lndp_layout``
   Specifies the layout options. Valid values: ``1x4`` | ``4x1`` | ``2x2``

``lndp_input_file``
   Specifies the path for the input file.

``output files``
   Specifies the path for the output file.

``lndp_var_list``
   Specifies the land perturbation variable options. Valid values: ``vgf`` | ``smc``

      +-------+------------------------------------------+
      | Value | Description                              |
      +=======+==========================================+
      | vgf   | Perturbs the vegetation green fraction   |
      +-------+------------------------------------------+
      | smc   | Perturbs the soil moisture               |
      +-------+------------------------------------------+

Example of a ``namelist.vector2tile`` Entry
----------------------------------------------

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
