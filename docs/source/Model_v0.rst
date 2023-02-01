.. _Model:

=================================
UFS Noah-MP Land Surface Model
=================================

This chapter provides practical information on building and running the Noah-MP Land Surface Model (LSM). 
It also contains information on required input files and the Vector-to-Tile Converter.
For background information on the evolution of the Unified Forecast System (:term:`UFS`) 
and the Noah-MP Land Surface Model (LSM), see :numref:`Section %s <Background>` of the Introduction. 

.. _BuildRun:

Building and Running the UFS Land Model
==========================================

Make sure your local system has a Fortran compiler and NetCDF software
installed.

#. Clone the UFS land model from GitHub:

   .. code-block:: console

      git clone --recurse-submodules
      https://github.com/barlage/ufs-land-driver.git

#. Navigate to the UFS land driver:

   .. code-block:: console

      cd ufs-land-driver

#. Create a ``user_build_config`` file:

   .. code-block:: console

      ./configure

#. Edit the ``user_build_config`` file to setup compiler and library
   paths to be consistent with your environment if not done by default:

   .. code-block:: console

      COMPILERF90 = /opt/local/bin/gfortran-mp-10
      FREESOURCE = #-ffree-form -ffree-line-length-none
      F90FLAGS = -fdefault-real-8 -fdefault-double-8
      NETCDFMOD = -I/opt/local/include
      NETCDFLIB = -L/opt/local/lib -lnetcdf -lnetcdff
      PHYSDIR = ../ccpp-physics/physics

   If you want to use a different ``ccpp-physics`` directory from the one
   automatically downloaded with the clone, set the ``PHYSDIR`` in
   ``user_build_config`` to point to the top of the ``ccpp-physics``
   directory (path relative to the ``mod`` directory).

   All the modules from ccpp-physics should be compiled in the ``mod``
   directory, all the drivers in the ``driver`` directory, and executables
   are in the ``run`` directory.

#. Compile the code:

   .. code-block:: console

      make

   If the code successfully compiles, you will see ``ufsLand.exe``
   in the ``run`` directory.

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

Static File
--------------

The static file includes the specific information on location, time,
soil layers, and variables that are required for the Noah-MP run. The
data can be provided in :term:`netCDF` format.

The static file is pre-staged and available to download here:

.. COMMENT: I think we need a link here...

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
   | gvf_monthly (green        | monthly green vegetation fraction        |
   | vegetation fraction)      |                                          |
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

Initial Conditions File
--------------------------

Land DA currently supports the snow DA initial conditions file
from the Noah-MP model. The initial conditions file includes the specific
information on location, time, soil layers, and variables that are
required for the UFS Land snow DA cycling. The data can be provided
in :term:`netCDF` format.

The initial condition file is pre-staged and available to download here:

.. COMMENT: I think we need a link here...

.. table:: Configuration variables specified in the static file (ufs-land_C96_static_fields.nc)

   +-----------------------------+----------------------------------------+
   | Configuration Variables     | Units                                  |
   +=============================+========================================+
   | time                        | seconds since 1970-01-01 00:00:00      |
   +-----------------------------+----------------------------------------+
   | date (date length)          | UTC date                               |
   +-----------------------------+----------------------------------------+
   | latitude                    | degrees_north                          |
   +-----------------------------+----------------------------------------+
   | longitude                   | degrees_east                           |
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

Model Configuration File
---------------------------

The UFS Land model uses a series of template files, combined with
user-selected settings, to create required name lists and parameter
files needed by the UFS Land DA workflow. This section describes the
options in the ``ufs-land.namelist.noahmp`` file.

**Run setup**

static_file : specifies the UFS Land static file.

init_file : specifies the UFS Land initial condition file.

forcing_dir : specifies the UFS Land forcing directory.

separate_output : specifies whether to enable the separate output. 
Acceptable values are:

+-----------------+----------------------------------------------------+
| **Value**       | **Description**                                    |
+-----------------+----------------------------------------------------+
| .false.         | do not enable                                      |
+-----------------+----------------------------------------------------+
| true            | enable                                             |
+-----------------+----------------------------------------------------+

output_dir : specifies the output directory.

restart_frequency_s : specifies the restart frequency (second)
   for the UFS Land model.

restart_simulation : specifies whether to enable the restart
   simulation. Acceptable values are:

+-----------------+----------------------------------------------------+
| **Value**       | **Description**                                    |
+-----------------+----------------------------------------------------+
| .false.         | do not enable                                      |
+-----------------+----------------------------------------------------+
| True            | enable                                             |
+-----------------+----------------------------------------------------+

..

restart_date : specifies the restart date. The form is
   YYYY-MM-DD HH:MM:SS, where YYYY is a 4-digit year, MM is a 2-digit
   month, DD is a 2-digit day, HH is a 2-digit hour, MM is a 2-digit
   minute, and SS is a 2-digit second.

restart_dir : specifies the restart directory.

timestep_seconds : specifies the timestep in seconds.

simulation_start : specifies the simulation start time. The
   form is YYYY-MM-DD HH:MM:SS, where YYYY is a 4-digit year, MM is a
   2-digit month, DD is a 2-digit day, HH is a 2-digit hour, MM is a
   2-digit minute, and SS is a 2-digit second.`

simulation_end : specifies the simulation end time. The form
   is YYYY-MM-DD HH:MM:SS, where YYYY is a 4-digit year, MM is a 2-digit
   month, DD is a 2-digit day, HH is a 2-digit hour, MM is a 2-digit
   minute, and SS is a 2-digit second.

run_days : specifies the number of days to run.

run_hours : specifies the number of hours to run.

run_minutes : specifies the number of minutes to run.

run_seconds : specifies the number of seconds to run.

run_timesteps : specifies the number of timesteps to run.

**Land model option**

   land_model : specifies which land surface model to use.
   Acceptable values are:

+-----------------+----------------------------------------------------+
| **Value**       | **Description**                                    |
+-----------------+----------------------------------------------------+
| 1               | Noah                                               |
+-----------------+----------------------------------------------------+
| 2               | Noah-MP                                            |
+-----------------+----------------------------------------------------+

**Structure**

num_soil_levels : specifies the number of soil levels.`

forcing_height : specifies the forcing height in meters.`

**Soil setup**

soil_level_thickness : specifies the thickness (in meters) of
   each of the soil layers (top layer to bottom layer).`

soil_level_nodes : specifies the soil level centroids from the
   surface (in meters).

**Noah-MP.4.0.1 options**

dynamic_vegetation_option : specifies the dynamic vegetation
   model option. Acceptable values are:

+----------------+-----------------------------------------------------+
| **Value**      | **Description**                                     |
+----------------+-----------------------------------------------------+
| 1              | off (use table LAI; use FVEG=SHDFAC from input)     |
+----------------+-----------------------------------------------------+
| 2              | on (dynamic vegetation; must use Ball-Berry         |
|                | canopy option)                                      |
+----------------+-----------------------------------------------------+
| 3              | off (use table LAI; calculate FVEG)                 |
+----------------+-----------------------------------------------------+
| 4              | off (use table LAI; use maximum vegetation          |
|                | fraction)                                           |
+----------------+-----------------------------------------------------+
| 5              | on (use maximum vegetation fraction)                |
+----------------+-----------------------------------------------------+
| 6              | on (use FVEG = SHDFAC from input)                   |
+----------------+-----------------------------------------------------+
| 7              | off (use input LAI; use FVEG = SHDFAC from          |
|                | input)                                              |
+----------------+-----------------------------------------------------+
| 8              | off (use input LAI; calculate FVEG)                 |
+----------------+-----------------------------------------------------+
| 9              | off (use input LAI; use maximum vegetation          |
|                | fraction)                                           |
+----------------+-----------------------------------------------------+
| 10             | crop model on (use maximum vegetation               |
|                | fraction)                                           |
+----------------+-----------------------------------------------------+

..

   LAI: routines for handling Leaf/Stem area index data products

   FVEG: green vegetation fraction [0.0-1.0]

   SHDFAC: greenness vegetation (shaded) fraction

   canopy_stomatal_resistance_option : specifies the canopy
   stomatal resistance option. Acceptable values are:

+----------------+-----------------------------------------------------+
| **Value**      | **Description**                                     |
+----------------+-----------------------------------------------------+
| 1              | Ball-Berry                                          |
+----------------+-----------------------------------------------------+
| 2              | Jarvis                                              |
+----------------+-----------------------------------------------------+

..

   soil_wetness_option : specifies the soil moisture factor for
   the stomatal resistance option. Acceptable values are:

+----------------+-----------------------------------------------------+
| **Value**      | **Description**                                     |
+----------------+-----------------------------------------------------+
| 1              | Noah (soil moisture)                                |
+----------------+-----------------------------------------------------+
| 2              | CLM (matric potential)                              |
+----------------+-----------------------------------------------------+
| 3              | SSiB (matric potential)                             |
+----------------+-----------------------------------------------------+

..

   runoff_option : specifies the runoff option. Acceptable values
   are:

+----------------+-----------------------------------------------------+
| **Value**      | **Description**                                     |
+----------------+-----------------------------------------------------+
| 1              | SIMGM: TOPMODEL with groundwater (Niu et al.        |
|                | 2007 JGR)`                                          |
+----------------+-----------------------------------------------------+
| 2              | SIMTOP: TOPMODEL with an equilibrium water          |
|                | table (Niu et al. 2005 JGR)                         |
+----------------+-----------------------------------------------------+
| 3              | Noah original surface and subsurface runoff         |
|                | (free drainage) (Schaake 1996)                      |
+----------------+-----------------------------------------------------+
| 4              | BATS surface and subsurface runoff (free            |
|                | drainage)                                           |
+----------------+-----------------------------------------------------+
| 5              | Miguez-Macho&Fan groundwater scheme                 |
|                | (Miguez-Macho et al. 2007 JGR; Fan et al. 2007      |
|                | JGR)                                                |
+----------------+-----------------------------------------------------+

..

   surface_exchange_option : specifies the surface layer drag
   coefficient option. Acceptable values are:

+----------------+-----------------------------------------------------+
| **Value**      | **Description**                                     |
+----------------+-----------------------------------------------------+
| 1              | Monin-Obukhov                                       |
+----------------+-----------------------------------------------------+
| 2              | original Noah (Chen 1997)                           |
+----------------+-----------------------------------------------------+

..

   supercooled_soilwater_option : specifies the supercooled
   liquid water option. Acceptable values are:

+----------------+-----------------------------------------------------+
| **Value**      | **Description**                                     |
+----------------+-----------------------------------------------------+
| 1              | no iteration (Niu and Yang, 2006 JHM)               |
+----------------+-----------------------------------------------------+
| 2              | Koren’s iteration (1999)                            |
+----------------+-----------------------------------------------------+

..

   frozen_soil_adjust_option : specifies the frozen soil
   permeability option. Acceptable values are:

+----------------+-----------------------------------------------------+
| **Value**      | **Description**                                     |
+----------------+-----------------------------------------------------+
| 1              | linear effects, more permeable (Niu and             |
|                | Yang, 2006, JHM)                                    |
+----------------+-----------------------------------------------------+
| 2              | nonlinear effects, less permeable (Koren            |
|                | 1999)                                               |
+----------------+-----------------------------------------------------+

..

   radiative_transfer_option : specifies the radiation transfer
   option. Acceptable values are:

+----------------+-----------------------------------------------------+
| **Value**      | **Description**                                     |
+----------------+-----------------------------------------------------+
| 1              | modified two-stream (gap = F(solar angle, 3D        |
|                | structure...)<1-FVEG)                               |
+----------------+-----------------------------------------------------+
| 2              | two-stream applied to grid-cell (gap = 0)           |
+----------------+-----------------------------------------------------+
| 3              | two-stream applied to a vegetated fraction          |
|                | (gap=1-FVEG)                                        |
+----------------+-----------------------------------------------------+

..

   snow_albedo_option : specifies the snow surface albedo option.
   Acceptable values are:

+----------------+-----------------------------------------------------+
| **Value**      | **Description**                                     |
+----------------+-----------------------------------------------------+
| 1              | BATS                                                |
+----------------+-----------------------------------------------------+
| 2              | CLASS                                               |
+----------------+-----------------------------------------------------+

..

   precip_partition_option : specifies the option for partitioning 
   precipitation into rainfall and snowfall. Acceptable values are:

+----------------+-----------------------------------------------------+
| **Value**      | **Description**                                     |
+----------------+-----------------------------------------------------+
| 1              | Jordan (1991)                                       |
+----------------+-----------------------------------------------------+
| 2              | BATS: when SFCTMP<TFRZ+2.2                          |
+----------------+-----------------------------------------------------+
| 3              | Noah: when SFCTMP<TFRZ                              |
+----------------+-----------------------------------------------------+
| 4              | Use WRF microphysics output                         |
+----------------+-----------------------------------------------------+

..

   SFCTMP : surface air temperature

   TFRZ : freezing/melting point (K)

   soil_temp_lower_bdy_option : specifies the lower boundary
   condition of soil temperature option. Acceptable values are:

+----------------+-----------------------------------------------------+
| **Value**      | **Description**                                     |
+----------------+-----------------------------------------------------+
| 1              | zero heat flux from the bottom (ZBOT and TBOT not   |
|                | used)                                               |
+----------------+-----------------------------------------------------+
| 2              | TBOT at ZBOT (8m) read from a file (original Noah)  |                          
+----------------+-----------------------------------------------------+

..

   TBOT : lower boundary soil temperature [K]

   ZBOT : depth[m] of lower boundary soil temperature (TBOT)

   soil_temp_time_scheme_option : specifies the snow and soil
   temperature time scheme. Acceptable values are:

+----------------+-----------------------------------------------------+
| **Value**      | **Description**                                     |
+----------------+-----------------------------------------------------+
| 1              | semi-implicit; flux top boundary condition          |
+----------------+-----------------------------------------------------+
| 2              | fully implicit (original Noah); temperature top     |
|                | boundary condition                                  |
+----------------+-----------------------------------------------------+
| 3              | same as 1, but FSNO for TS calculation (generally   |
|                | improves snow; v3.7)                                |
+----------------+-----------------------------------------------------+

..

   FSNO: fraction of surface covered with snow

   TS: surface temperature

   surface_evap_resistance_option : specifies the surface resistance
   option. Acceptable values are:

+----------------+-----------------------------------------------------+
| **Value**      | **Description**                                     |
+----------------+-----------------------------------------------------+
| 1              | Sakaguchi and Zeng, 2009                            |
+----------------+-----------------------------------------------------+
| 2              | Sellers (1992)                                      |
+----------------+-----------------------------------------------------+
| 3              | adjusted Sellers to decrease RSURF for wet soil     |
+----------------+-----------------------------------------------------+
| 4              | option 1 for non-snow; rsurf = rsurf_snow for snow  |
+----------------+-----------------------------------------------------+

..

   rsurf: ground surface resistance (s/m)

   glacier_option : specifies the glacier model option. Acceptable
   values are:

+----------------+-----------------------------------------------------+
| **Value**      | **Description**                                     |
+----------------+-----------------------------------------------------+
| 1              | include phase change of ice                         |
+----------------+-----------------------------------------------------+
| 2              | simple (ice treatment more like original Noah)      |
+----------------+-----------------------------------------------------+

**Forcing**

   forcing_timestep_seconds : specifies the timestep of forcing
   in seconds.

   forcing_type : specifies the forcing type option. Acceptable
   values are:

+----------------+-----------------------------------------------------+
| **Value**      | **Description**                                     |
+----------------+-----------------------------------------------------+
| single-point   |                                                     |
+----------------+-----------------------------------------------------+
|                |                                                     |
+----------------+-----------------------------------------------------+
|                |                                                     |
+----------------+-----------------------------------------------------+
|                |                                                     |
+----------------+-----------------------------------------------------+

..

   forcing_filename : specifies the forcing file name. Acceptable
   values are:

+----------------+-----------------------------------------------------+
| **Value**      | **Description**                                     |
+----------------+-----------------------------------------------------+
| C96_           |                                                     |
| _GDAS_forcing  |                                                     |
+----------------+-----------------------------------------------------+
| C96_           |                                                     |
| GEFS_forcing   |                                                     |
+----------------+-----------------------------------------------------+
| C96_GS         |                                                     |
| WP3_forcing    |                                                     |
+----------------+-----------------------------------------------------+

..

   forcing_interp_solar : specifies the interpolation option for
   solar radiation. Acceptable values are:

+----------------+-----------------------------------------------------+
| **Value**      | **Description**                                     |
+----------------+-----------------------------------------------------+
| linear         |                                                     |
+----------------+-----------------------------------------------------+
|                |                                                     |
+----------------+-----------------------------------------------------+
|                |                                                     |
+----------------+-----------------------------------------------------+
|                |                                                     |
+----------------+-----------------------------------------------------+

..

   forcing_name_precipitation : specifies the name of forcing
   precipitation.

   forcing_name_temperature : specifies the name of forcing
   temperature.

   forcing_name_specific_humidity : specifies the name of forcing
   specific-humidity.

   forcing_name_wind_speed : specifies the name of forcing wind
   speed.

   forcing_name_pressure : specifies the name of forcing surface
   pressure.

   forcing_name_sw_radiation : specifies the name of forcing
   shortwave radiation.

   forcing_name_lw_radiation : specifies the name of forcing
   longwave radiation.

Example of ‘ufs-land.namelist.noahmp’ entry

&run_setup

static_file =
"/scratch1/NCEPDEV/stmp2/Michael.Barlage/forcing/C96/static/ufs-land_C96_static_fields.nc"

init_file =
"/scratch1/NCEPDEV/stmp2/Michael.Barlage/forcing/C96/init/ufs-land_C96_init_fields_1hr.nc"

forcing_dir = "/scratch2/NCEPDEV/stmp3/Zhichang.Guo/GEFS/regrid/"

separate_output = .true.

output_dir = "./noahmp_output/"

restart_frequency_s = 86400

restart_simulation = .true.

restart_date = "XXYYYY-XXMM-XXDD XXHH:00:00"

restart_dir = "./restarts/vector/"

timestep_seconds = 3600

! simulation_start is required

! either set simulation_end or run\_\* or run_timesteps, priority

! 1. simulation_end 2. run\_[days/hours/minutes/seconds] 3.
run_timesteps

simulation_start = "2000-01-01 00:00:00" ! start date [yyyy-mm-dd
hh:mm:ss]

! simulation_end = "1999-01-01 06:00:00" ! end date [yyyy-mm-dd
hh:mm:ss]

run_days = 1 ! number of days to run

run_hours = 0 ! number of hours to run

run_minutes = 0 ! number of minutes to run

run_seconds = 0 ! number of seconds to run

run_timesteps = 0 ! number of timesteps to run

begloc = 1

endloc = 18360

/

&land_model_option

land_model = 2 ! choose land model: 1=noah, 2=noahmp

/

&structure

num_soil_levels = 4 ! number of soil levels

forcing_height = 6 ! forcing height [m]

/

&soil_setup

soil_level_thickness = 0.10, 0.30, 0.60, 1.00 ! soil level thicknesses
[m]

soil_level_nodes = 0.05, 0.25, 0.70, 1.50 ! soil level centroids from
surface [m]

/

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

/

&forcing

forcing_timestep_seconds = 10800

forcing_type = "gswp3"

forcing_filename = "C96_GEFS_forcing\_"

forcing_interp_solar = "gswp3_zenith" ! gswp3_zenith or linear

forcing_time_solar = "gswp3_average" ! gswp3_average or instantaneous

forcing_name_precipitation = "precipitationXXMEM"

forcing_name_temperature = "temperatureXXMEM"

forcing_name_specific_humidity = "specific_humidityXXMEM"

forcing_name_wind_speed = "wind_speedXXMEM"

forcing_name_pressure = "surface_pressureXXMEM"

forcing_name_sw_radiation = "solar_radiationXXMEM"

forcing_name_lw_radiation = "longwave_radiationXXMEM"

/

.. _VectorTileConverter:

Vector to Tile Converter
==================================

The vector to tile convertor is used for mapping between vector format
used by the Noah-MP offline driver, and the tile format used by the UFS
atmospheric model. This is currently used to prepare input tile files
for JEDI. Note that these files include only those fields required by
JEDI, rather than the full restart.

Building and Running the Vector to Tile Converter
-----------------------------------------------------

   1. Clone the UFS land model from GitHub:

git clone --recurse-submodules
https://github.com/NOAA-PSL/land-vector2tile

2. Navigate to the land vector to tile:

..

   cd land-vector2tile

3. Configure

..

   ./configure

4. To compile:

Make

5. To run:

Vector2tile_converter.exe namelist.vector2tile

Configuration File
---------------------

This section describes the options in the ‘namelist.vector2tile’ file.

**Run setup**

   direction : specifies the conversion option. Acceptable values
   are:

+----------------+-----------------------------------------------------+
| **Value**      | **Description**                                     |
+----------------+-----------------------------------------------------+
| vector2tile    | vector to tile conversion for restart file          |
+----------------+-----------------------------------------------------+
| tile2vector    | tile to vector conversion for restart file          |
+----------------+-----------------------------------------------------+
| lndp2tile      | land perturbation to tile                           |
+----------------+-----------------------------------------------------+
| lndp2vector    | land perturbation to vector                         |
+----------------+-----------------------------------------------------+

**FV3 resolution and path to orographic files for restart/perturbation
conversion**

tile_size : specifies the size of tile.

tile path : specifies the path of tile location.

tile_fstub : specifies the name of orographic tile

**This part is only for restart conversion**

static_filename : specifies the path for static file.

vector_restart_path : specifies the location of vector restart file,
   vector to tile direction.

tile_restart_path : specifies the location of tile restart file, tile
   to vector direction.

output_path : specifies the path for converted files. If this is same
   as tile/vector path, the files may be overwritten.

**This part is only for perturbation mapping**

lndp_layout : specifies the layout options. Acceptable values are:

+----------------+-----------------------------------------------------+
| **Value**      | **Description**                                     |
+----------------+-----------------------------------------------------+
| 1x4            |                                                     |
+----------------+-----------------------------------------------------+
| 4x1            |                                                     |
+----------------+-----------------------------------------------------+
| 2x2            |                                                     |
+----------------+-----------------------------------------------------+

..

lndp_input_file : specifies the path for input file.

output files : specifies the path for output file

lndp_var_list : specifies the land perturbation variable options.
   Acceptable values are:

+----------------+-----------------------------------------------------+
| **Value**      | **Description**                                     |
+----------------+-----------------------------------------------------+
| vgf            |                                                     |
+----------------+-----------------------------------------------------+
| smc            |                                                     |
+----------------+-----------------------------------------------------+
|                |                                                     |
+----------------+-----------------------------------------------------+

Example of ‘namelist.vector2tile’ entry

&run_setup

!------------------- common -------------------

! Direction of conversion: either "vector2tile" or "tile2vector" for
restart file

! "lndp2tile" or "lndp2vector" for perturbation

direction = "vector2tile"

! FV3 resolution and path to oro files for restart/perturbation
conversion

tile_size = 96

tile_path =
"/scratch1/NCEPDEV/stmp2/Michael.Barlage/models/vector/v2t_data/tile_files/C96.mx100_frac/"

tile_fstub = "oro_C96.mx100"

!------------------- only restart conversion -------------------

! Time stamp for conversion for restart conversion

restart_date = "2019-09-30 23:00:00"

! Path for static file

static_filename="/scratch1/NCEPDEV/stmp2/Michael.Barlage/forcing/C96/static/ufs-land_C96_static_fields.nc"

! Location of vector restart file (vector2tile direction)

vector_restart_path =
"/scratch1/NCEPDEV/stmp2/Michael.Barlage/models/vector/v2t_data/restart/"

! Location of tile restart files (tile2vector direction)

tile_restart_path =
"/scratch1/NCEPDEV/stmp2/Michael.Barlage/models/vector/v2t_data/workshop/"

! Path for converted files; if same as tile/vector path, files may be
overwritten

output_path =
"/scratch1/NCEPDEV/stmp2/Michael.Barlage/models/vector/v2t_data/workshop/"

!------------------- only perturbation mapping -------------------

! layout, options: 1x4, 4x1, 2x2, an input settings for generating the
perturbation file

lndp_layout = "1x4"

! input files

lndp_input_file =
"/scratch2/NCEPDEV/land/data/DA/ensemble_pert/workg_T162_984x488.tileXX.nc"

! output files

lndp_output_file = "./output.nc"

! land perturbation variable list

lndp_var_list='vgf','smc'

/

