.. _BuildRunLandDA:

************************************
Land DA Workflow (Hera & Orion)
************************************

This chapter provides basic instructions for building and running a basic Land DA case for the Unified Forecast System (:term:`UFS`) Land Data Assimilation System (Land DA). This "out-of-the-box" Land DA case builds a weather forecast for January 1-2, 2016. These steps will work on Hera and Orion systems. It is recommended that users on other systems run the containerized version of Land DA. Users may reference :numref:`Chapter %s: Running Land DA in a Container <Container>` for instructions. The Land DA container packages together the Land DA system with its dependencies (e.g., :term:`spack-stack`, :term:`JEDI`) and provides a uniform enviroment in which to build and run the Land DA System. This approach is recommended for users not running Land DA on a supported :ref:`Level 1 <LevelsOfSupport>` system (e.g., Hera, Orion). 

.. COMMENT: Check expt date

#. Create a directory for the Land DA experiment (``$LANDDAROOT``).

   .. code-block:: console

      mkdir /path/to/landda
      cd /path/to/landda
      export LANDDAROOT=`pwd`

#. Get data. On Level 1 NOAA RDHPCS systems (i.e., Hera and Orion), users must can either set the ``LANDDA_INPUTS`` variable to the location of their system's pre-staged data (see :numref:`Table %s <Level1Data>`) or use a soft link to the data. For example, on Hera, users may set: 
   
   .. COMMENT: Check whether we can user $EPICHOME at this point!

   .. code-block:: console

      export LANDDA_INPUTS=/scratch1/NCEPDEV/nems/role.epic/landda/inputs

   .. _Level1Data:

   .. table:: Level 1 RDHPCS System Data

      +-----------+--------------------------------------------------+
      | Platform  | Data Location                                    |
      +===========+==================================================+
      | Hera      | /scratch1/NCEPDEV/nems/role.epic/landda/inputs   |
      +-----------+--------------------------------------------------+
      | Orion     | /work/noaa/epic-ps/role-epic-ps/landda/inputs    |
      +-----------+--------------------------------------------------+

   Alternatively, users can use a soft link to the data. For example, on Orion:

   .. code-block:: console

      cd $LANDDAROOT
      ln -s $EPICHOME/landda/inputs .

   Users who are not on Hera or Orion should view :numref:`Chapter %s <Container>` for instructions on running the containerized version of Land DA. :numref:`Section %s <GetData>` explains options for downloading sample data. 

#. Clone the Land DA repository:

   .. code-block:: console

      git clone -b release/public-v1.0.0 --recursive https://github.com/NOAA-EPIC/land-offline_workflow.git

#. ``cd`` into the workflow directory, and source the modulefiles.

   .. code-block:: console

      cd land-offline_workflow
      module use modulefiles
      module load landda_<machine>.intel
   
   where ``<machine>`` is either ``hera`` or ``orion``. 

#. Create and navigate to a build directory.

   .. code-block:: console

      mkdir build
      cd build

#. Build the Land DA system.

   .. code-block:: console

      ecbuild ..
      make -j 8

   If the code successfully compiles, the console output should end with:
   
   .. code-block:: console

      [100%] Built target ufsLandDriver.exe
   
   Additionally, the ``build`` directory will contain several files and a ``bin`` subdirectory with three executables: 

      * ``apply_incr.exe``
      * ``ufsLandDriver.exe``
      * ``vector2tile_converter.exe``

#. Navigate back to the ``land-offline_workflow`` directory and check that the account/partition is correct in ``submit_cycle.sh``. 

   .. code-block:: console

      cd ..
      vi submit_cycle.sh

   If necessary, modify line 3 to include the correct account and queue(s) (qos) for the system. It may also be necessary to add the following line to the script to specify the partition: 

   .. code-block:: console

      #SBATCH –partition=my_partition
   
#. Configure the experiment: 


#. Run the experiment:

   .. code-block:: console

      # For 2016 data: 
      ./do_submit_cycle.sh settings_DA_cycle_gdas
      # OR for 2020 data:
      ./do_submit_cycle.sh settings_DA_cycle_era5

   The system will output a message such as ``Submitted batch job ########``, indicating that the job was successfully submitted. If all goes well, two full cycles will run with data assimilation (DA) and a forecast. 

#. To check on the job status, run: 

   .. code-block:: console

      squeue -u $USER

   To view progress, users can open the ``log`` and ``err`` files:

   .. code-block:: console

      tail -f log* err*

   Users will need to hit ``Ctrl+C`` to exit the file. 

   .. attention::

      If the log file contains a NetCDF error (e.g., ``ModuleNotFoundError: No module named 'netCDF4'``), run:
      
      .. code-block:: console
         
         python -m pip install netCDF4
      
      Then, resubmit the job (``sbatch submit_cycle.sh``).

   Next, check for the background and analysis files in the ``cycle_land`` directory.

   .. code-block:: console

      ls -l ../cycle_land/DA_GHCN_test/mem000/restarts/vector/



..

   .. table:: Data Locations on Level 1 Systems

   +-----------+-----------------------------------------------------------------------------+
   | Platform  | Data Path                                                                   |
   +===========+=============================================================================+
   | Hera      | /scratch1/NCEPDEV/nems/role.epic/landda/inputs/DA/snow_depth/GHCN/data_proc |
   +-----------+-----------------------------------------------------------------------------+
   | Orion     | /work/noaa/epic-ps/role-epic-ps/landda/inputs/DA/snow_depth/GHCN/data_proc  |
   +-----------+-----------------------------------------------------------------------------+
