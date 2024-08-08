.. _Model:

*****************************************
Input/Output Files for the Noah-MP Model
*****************************************

This chapter provides practical information on input files and parameters for the Noah-MP Land Surface Model (LSM) and its Vector-to-Tile Converter component.
For background information on the Noah-MP LSM, see :numref:`Section %s <NoahMP>` of the Introduction. 

.. _InputFiles:

Input Files 
**************

The UFS land model requires multiple input files to run, including static datasets (fix files containing climatological information, terrain, and land use data), initial conditions files, and forcing files. 
Users may reference the `Community Noah-MP Land Surface Modeling System Technical Description Version 5.0 <https://opensky.ucar.edu/islandora/object/technotes:599>`_ (2023) and the `Community Noah-MP User's Guide <https://www.jsg.utexas.edu/noah-mp/files/Users_Guide_v0.pdf>`_ (2011) for a detailed technical description of certain elements of the Noah-MP model.

In both the land component and land driver implementations of Noah-MP, static file(s) and initial conditions file(s) specify model parameters. 
These files are publicly available in the `Land DA data bucket <https://registry.opendata.aws/noaa-ufs-land-da/>`_. 
Users can download the data and untar the file via the command line:

.. _TarFile:

.. code-block:: console

   wget https://noaa-ufs-land-da-pds.s3.amazonaws.com/develop-20240501/Landda_develop_data.tar.gz
   tar xvfz Landda_develop_data.tar.gz

For data specific to the latest release (|latestr|), users can run: 

.. code-block:: console
   
   wget https://noaa-ufs-land-da-pds.s3.amazonaws.com/current_land_da_release_data/v1.2.0/Landdav1.2.0_input_data.tar.gz
   tar xvfz Landdav1.2.0_input_data.tar.gz

These files and their parameters are described in the following subsections.


.. _view-netcdf-files:

Viewing netCDF Files
======================

Users can view file information, variables, and notes for NetCDF files using the ``ncdump`` module. On Level 1 platforms, users can load the Land DA environment from ``land-DA_workflow`` as described in :numref:`Section %s <config-wflow>`. 

Then, users can run ``ncdump -h path/to/filename.nc``, where ``path/to/filename.nc`` is replaced with the path to the file. For example, on Orion, users might run: 

.. code-block:: console

   module load netcdf-c/4.9.2
   ncdump -h /work/noaa/epic/UFS_Land-DA_Dev/inputs/NOAHMP_IC/ufs-land_C96_init_fields.tile1.nc


On other systems, users can load a compiler, MPI, and NetCDF modules before running the ``ncdump`` command above. For example: 

.. code-block:: console

   module load intel/2022.1.2 impi/2022.1.2 netcdf-c/4.9.2
   ncdump -h /path/to/inputs/NOAHMP_IC/ufs-land_C96_init_fields.tile1.nc

Users may need to modify the ``module load`` command to reflect modules that are available on their system. 

.. _datm-lnd-input-files:

Input Files for the ``DATM`` + ``LND`` Configuration with GSWP3 data
======================================================================

With the integration of the UFS Noah-MP land component into the Land DA System in the v1.2.0 release, model forcing options have been enhanced so that users can run the UFS land component (:term:`LND`) with the data atmosphere component (:term:`DATM`). Updates provide a new analysis option on the cubed-sphere native grid using :term:`GSWP3` forcing data to run a cycled experiment for 2000-01-03 to 2000-01-04. An artificial GHCN snow depth observation is provided for data assimilation (see :numref:`Section %s <observation-data>` for more on GHCN files). The GHCN observations will be extended in the near future. 

On Level 1 platforms, the requisite data are pre-staged at the locations listed in :numref:`Section %s <Level1Data>`. The data are also publicly available via the `Land DA Data Bucket <https://registry.opendata.aws/noaa-ufs-land-da/>`_. 

.. attention::

   The DATM + LND option is only supported on Level 1 systems (i.e., Hera and Orion). It is not tested or supported using a container except on Hera and Orion. 

Forcing Files
---------------

:term:`Forcing files<forcing data>` for the land component configuration come from the Global Soil Wetness Project Phase 3 dataset. They are located in the ``inputs/DATM_input_data/gswp3`` directory (downloaded :ref:`above <InputFiles>`).

.. code-block:: console 

   clmforc.GSWP3.c2011.0.5x0.5.Prec.1999-12.nc
   clmforc.GSWP3.c2011.0.5x0.5.Prec.2000-01.nc
   clmforc.GSWP3.c2011.0.5x0.5.Solr.1999-12.nc
   clmforc.GSWP3.c2011.0.5x0.5.Solr.2000-01.nc
   clmforc.GSWP3.c2011.0.5x0.5.TPQWL.1999-12.nc
   clmforc.GSWP3.c2011.0.5x0.5.TPQWL.2000-01.nc
   clmforc.GSWP3.c2011.0.5x0.5.TPQWL.SCRIP.210520_ESMFmesh.nc
   fv1.9x2.5_141008_ESMFmesh.nc
   topodata_0.9x1.25_USGS_070110_stream_c151201.nc
   topodata_0.9x1.SCRIP.210520_ESMFmesh.nc

These files provide atmospheric forcing data related to precipitation, solar radiation, longwave radiation, temperature, pressure, winds, humidity, topography, and mesh data. 

Noah-MP Initial Conditions
----------------------------

The offline Land DA System currently only supports snow DA. 
The initial conditions files include the initial state variables that are required for the UFS land snow DA to begin a cycling run. The data must be provided in :term:`netCDF` format. 

By default, on Level 1 systems and in the Land DA data bucket, the initial conditions files are located at ``inputs/NOAHMP_IC/ufs-land_C96_init_fields.tile*.nc`` (downloaded :ref:`above <InputFiles>`). Each file corresponds to one of the six tiles of the `global FV3 grid <https://www.gfdl.noaa.gov/fv3/fv3-grids/>`_.  

The files contain the following data:             

.. list-table:: *Variables specified in the initial conditions file ufs-land_C96_init_fields.tile*.nc*
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


FV3_fix_tiled Files
---------------------

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
   grid_spec.nc
   oro_C96.mx100.tile*.nc

The ``C96_grid.tile*.nc`` files contain grid information for tiles 1-6 at C96 grid resolution. The ``grid_spec.nc`` file contains information on the mosaic grid. 

.. note:: 

   ``grid_spec.nc`` and ``C96.mosaic.nc`` are the same file under different names and may be used interchangeably. 


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

.. list-table:: Input Files Containing Grid Information
   :widths: 30 70
   :header-rows: 1

   * - Filename
     - Description
   * - Cxx_grid.tile[1-6].nc
     - Cxx grid information for tiles 1-6, where ``xx`` is the grid resolution.
   * - Cxx_oro_data.tile[1-6].nc 
       
       oro_Cxx.mx100.tile[1-6].nc

     - Orography files that contain grid and land mask information. 
       Cxx refers to the atmospheric resolution, and mx100 refers to the ocean 
       resolution (100=1º). Both file names refer to the same file; there are symbolic links between them. 

Configuration File
======================

This section describes the options in the ``namelist.vector2tile`` file (derived from ``parm/template.vector2tile`` files. )

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

``restart_date``
   Specifies the time stamp for restart conversion in "YYYY-MM-DD HH:00:00" format. 

``static_filename``
   Specifies the path for static file.

``vector_restart_path``
   Specifies the location of vector restart file, vector-to-tile direction.

``tile_restart_path``
   Specifies the location of tile restart file, tile-to-vector direction.

``output_path``
   Specifies the path for converted files. If this is same as tile/vector path, the files may be overwritten.

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
