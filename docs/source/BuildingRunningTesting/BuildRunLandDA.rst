.. _BuildRunLandDA:

************************************
Land DA Workflow (Hera & Orion)
************************************

This chapter provides instructions for building and running basic Land DA cases for the Unified Forecast System (:term:`UFS`) Land DA System. Users can choose between two options: 

   * A Dec. 21, 2019 00z sample case using ERA5 data with the UFS Land Driver (``settings_DA_cycle_era5``)
   * A Jan. 3, 2000 00z sample case using GSWP3 data with the UFS Noah-MP land component (``settings_DA_cycle_gswp3``). 

.. attention::
   
   These steps are designed for use on :ref:`Level 1 <LevelsOfSupport>` systems (i.e., Hera and Orion) and may require significant changes on other systems. It is recommended that users on other systems run the containerized version of Land DA. Users may reference :numref:`Chapter %s: Containerized Land DA Workflow <Container>` for instructions. 

Create a Working Directory
*****************************

Create a directory for the Land DA experiment (``$LANDDAROOT``):

.. code-block:: console

   mkdir /path/to/landda
   cd /path/to/landda
   export LANDDAROOT=`pwd`

where ``/path/to/landda`` is the path to the directory where the user plans to run Land DA experiments. 

.. _GetData:

Get Data
***********

:numref:`Table %s <Level1Data>` shows the locations of pre-staged data on NOAA :term:`RDHPCS` (i.e., Hera and Orion). 
   
.. _Level1Data:

.. table:: Level 1 RDHPCS Data

   +-----------+--------------------------------------------------+
   | Platform  | Data Location                                    |
   +===========+==================================================+
   | Hera      | /scratch2/NAGAPE/epic/UFS_Land-DA/inputs         |
   +-----------+--------------------------------------------------+
   | Orion     | /work/noaa/epic/UFS_Land-DA/inputs               |
   +-----------+--------------------------------------------------+

Users can either set the ``LANDDA_INPUTS`` environment variable to the location of their system's pre-staged data or use a soft link to the data. For example, on Hera, users may set: 

.. code-block:: console

   export LANDDA_INPUTS=/scratch2/NAGAPE/epic/UFS_Land-DA/inputs

Alternatively, users can add a soft link to the data. For example, on Orion:

.. code-block:: console

   cd $LANDDAROOT
   ln -fs /work/noaa/epic/UFS_Land-DA/inputs

Users who have difficulty accessing the data on Hera or Orion may download it according to the instructions in :numref:`Section %s <GetDataC>`. Users with access to data for additional experiments may use the same process described above to point or link to that data by modifying the path to the data appropriately. 

Users who are not using Land DA on Hera or Orion should view :numref:`Chapter %s <Container>` for instructions on running the containerized version of Land DA. :numref:`Section %s <GetDataC>` explains options for downloading the sample data onto their system. 

Get Code
***********

Clone the Land DA repository. To clone the ``develop`` branch, run: 

.. code-block:: console

   git clone -b develop --recursive https://github.com/ufs-community/land-DA_workflow.git

To clone the most recent release, run the same command with |branch| in place of ``develop``: 

.. code-block:: console

   git clone -b release/public-v1.2.0 --recursive https://github.com/ufs-community/land-DA_workflow.git

.. _build-land-da:

Build the Land DA System
***************************

#. Navigate to the ``sorc`` directory.

   .. code-block:: console

      cd $LANDDAROOT/land-DA_workflow/sorc

#. Run the build script ``app_build.sh``:

   .. code-block:: console

      ./app_build.sh

   If the code successfully compiles, the console output should end with:
   
   .. code-block:: console

      [100%] Completed 'ufs_model.fd'
      [100%] Built target ufs_model.fd
      ... Moving pre-compiled executables to designated location ...
   
   Additionally, the ``exec`` directory will contain the following executables: 

      * ``apply_incr.exe``
      * ``ufsLand.exe``
      * ``vector2tile_converter.exe``
      * ``tile2tile_converter.exe``
      * ``ufs_model``

.. _config-wflow:

Configure an Experiment
*************************

.. _load-env:

Load the Workflow Environment
===============================

To load the workflow environment, run: 

.. code-block:: console

   cd $LANDDAROOT/land-DA_workflow
   module use modulefiles
   module load wflow_<platform>
   conda activate land_da

where ``<platform>`` is ``hera`` or ``orion``. 

Modify the Workflow Configuration YAML
========================================

The ``develop`` branch includes two default experiments: 

   * A Dec. 21, 2019 00z sample case using the UFS Land Driver.
   * A Jan. 3, 2000 00z sample case using the UFS Noah-MP land component. 

Copy the experiment settings into ``land_analysis.yaml``:

.. code-block:: console

   cd $LANDDAROOT/land-DA_workflow/parm
   cp land_analysis_<forcing>_<platform>.yaml land_analysis.yaml

where: 

   * ``<platform>`` is ``hera`` or ``orion``.
   * ``<forcing>`` is either ``gswp3`` or ``era5`` forcing data.

Users may configure other elements of an experiment in ``land_analysis.yaml`` if desired. The ``land_analysis_*`` files contain reasonable default values for running a Land DA experiment. Users who wish to run a more complex experiment may change the values in these files and the files they reference using information in Sections :numref:`%s <Model>` & :numref:`%s <DASystem>`. 

.. _generate-wflow:

Generate the Rocoto XML File
==============================

Generate the workflow by running: 

.. code-block:: console

   uw rocoto realize --input-file land_analysis.yaml --output-file land_analysis.xml

Run the Experiment
********************

To run the experiment, issue a ``rocotorun`` command from the _____ directory: 

.. code-block:: console

   rocotorun -w land_analysis.xml -d land_analysis.db



Run an Experiment
********************

The Land DA System uses a script-based workflow that is launched using the ``do_submit_cycle.sh`` script. This script requires a ``settings_DA_cycle_*`` input file that details all the specifics of a given experiment. For example, to run the ERA5 case, users would run:

.. code-block:: console

   ./do_submit_cycle.sh settings_DA_cycle_era5
      
Users can replace ``settings_DA_cycle_era5`` with a different settings file to run a different default experiment. Regardless of the file selected, the system will output a message such as ``Submitted batch job ########``, indicating that the job was successfully submitted. If all goes well, one full cycle will run with data assimilation (DA) and a forecast. 

.. _VerifySuccess:

Check Progress
*****************

To check on the experiment status, users on a system with a Slurm job scheduler may run: 

.. code-block:: console

   squeue -u $USER

To view progress, users can open the ``log*`` and ``err*`` files once they have been generated:

.. code-block:: console

   tail -f log* err*

Users will need to type ``Ctrl+C`` to exit the files. For examples of what the log and error files should look like in a successful experiment, reference :ref:`ERA5 Experiment Logs <era5-log-output>` or :ref:`GSWP3 Experiment Logs <gswp3-log-output>` below. 

.. attention::

   If the log file contains a NetCDF error (e.g., ``ModuleNotFoundError: No module named 'netCDF4'``), run:
      
   .. code-block:: console
         
      python -m pip install netCDF4
      
   Then, resubmit the job (``sbatch submit_cycle.sh``).

Next, check for the background and analysis files in the test directory.

.. code-block:: console

   ls -l ../landda_expts/DA_<data_source>_test/mem000/restarts/<vector/tile>``

where: 

   * ``<data_source>`` is either ``era5`` or ``gswp3``, and
   * ``<vector/tile>`` is either ``vector`` or ``tile`` depending on whether ERA5 or GSWP3 forcing data was used, respectively. 

The experiment should generate several files. 

.. _era5-log-output:

ERA5 Experiment Logs
=====================

For the ERA5 experiment, the ``log*`` file for a successful experiment will a message like:

.. code-block:: console

   Creating: .//ufs_land_restart.2019-12-22_00-00-00.nc
   Searching for forcing at time: 2019-12-22 01:00:00
   
The ``err*`` file for a successful experiment will end with something similar to:

.. code-block:: console

   + THISDATE=2019122200
   + date_count=1
   + '[' 1 -lt 1 ']'
   + '[' 2019122200 -lt 2019122200 ']'

.. _gswp3-log-output:

GSWP3 Experiment Logs
=======================

For the GSWP3 experiment, the ``log*`` file for a successful experiment will end with a list of resource statistics. For example:

.. code-block:: console

   Number of times filesystem performed OUTPUT          = 250544
   Number of Voluntary Context Switches                 = 3252
   Number of InVoluntary Context Switches               = 183
   *****************END OF RESOURCE STATISTICS*************************
   
The ``err*`` file for a successful experiment will end with something similar to:

.. code-block:: console

   + echo 'do_landDA: calling apply snow increment'
   + [[ '' =~ hera\.internal ]]
   + /apps/intel-2022.1.2/intel-2022.1.2/mpi/2021.5.1/bin/mpiexec -n 6 /path/to/land-DA_workflow/build/bin/apply_incr.exe /path/to/landda_expts/DA_GSWP3_test/DA/logs//apply_incr.log
   + [[ 0 != 0 ]]
   + '[' YES == YES ']'
   + '[' YES == YES ']'
   + cp /path/to/workdir/mem000/jedi/20000103.000000.xainc.sfc_data.tile1.nc /path/to/workdir/mem000/jedi/20000103.000000.xainc.sfc_data.tile2.nc /path/to/workdir/mem000/jedi/20000103.000000.xainc.sfc_data.tile3.nc /path/to/workdir/mem000/jedi/20000103.000000.xainc.sfc_data.tile4.nc /path/to/workdir/mem000/jedi/20000103.000000.xainc.sfc_data.tile5.nc /path/to/workdir/mem000/jedi/20000103.000000.xainc.sfc_data.tile6.nc /path/to/landda_expts/DA_GSWP3_test/DA/jedi_incr/
   + [[ YES == \N\O ]]
