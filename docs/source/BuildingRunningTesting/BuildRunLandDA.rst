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

Users will need to configure certain elements of their experiment in ``land_analysis.yaml``: 

   * ``ACCOUNT:`` A valid account name. Hera, Orion, and most NOAA RDHPCS systems require a valid account name; other systems may not
   * ``EXP_NAME:`` An experiment name of the user's choice
   * ``EXP_BASEDIR:`` The full path to the directory where land-DA_workflow was cloned (i.e., ``$LANDDAROOT``)
   * ``JEDI_INSTALL:`` The full path to the system's ``jedi-bundle`` installation
   * ``LANDDA_INPUTS:`` The full path to the experiment data

.. note::

   To determine an appropriate ``ACCOUNT`` field for Level 1 systems running the Slurm job scheduler, run ``saccount_params``. On other systems, running ``groups`` will return a list of projects that the user has permissions for. Not all listed projects/groups have an HPC allocation, but those that do are potentially valid account names. 

Users may configure other elements of an experiment in ``land_analysis.yaml`` if desired. The ``land_analysis_*`` files contain reasonable default values for running a Land DA experiment. Users who wish to run a more complex experiment may change the values in these files and the files they reference using information in Sections :numref:`%s <Model>` & :numref:`%s <DASystem>`. 

.. _generate-wflow:

Generate the Rocoto XML File
==============================

Generate the workflow with ``uwtools`` by running: 

.. code-block:: console

   uw rocoto realize --input-file land_analysis.yaml --output-file land_analysis.xml

If the command runs without problems, ``uwtools`` will output a message similar to the following: 

.. code-block:: console

   [2024-03-01T20:36:03]     INFO 0 UW schema-validation errors found
   [2024-03-01T20:36:03]     INFO 0 Rocoto validation errors found

Run the Experiment
********************

To run the experiment, issue a ``rocotorun`` command from the ``parm`` directory: 

.. code-block:: console

   rocotorun -w land_analysis.xml -d land_analysis.db

.. _VerifySuccess:

Check Progress
*****************

Check Experiment Status
========================

To view the experiment status, run: 

.. code-block:: console

   rocotostat -w land_analysis.xml -d land_analysis.db

If ``rocotorun`` was successful, the ``rocotostat`` command will print a status report to the console. For example:

.. code-block:: console

   CYCLE              TASK                 JOBID        STATE   EXIT STATUS   TRIES   DURATION
   ======================================================================================================
   200001030000    prepexp   druby://hfe08:41879   SUBMITTING             -       2        0.0
   200001030000    prepobs                     -            -             -       -          -
   200001030000   prepbmat                     -            -             -       -          -
   200001030000     runana                     -            -             -       -          -
   200001030000    runfcst                     -            -             -       -          -

Users will need to issue the ``rocotorun`` command multiple times. The tasks must run in order, and ``rocotorun`` initiates the next task once its dependencies have completed successfully. Note that the status table printed by ``rocotostat`` only updates after each ``rocotorun`` command. For each task, a ``slurm-########.out`` log file is generated. A task that runs successfully will include a message with ``exit code 0:0`` at the bottom of the file: 

.. code-block:: console

   _______________________________________________________________
   Start Epilog on node h24c45 for job 56463665 :: Fri Mar  1 22:38:34 UTC 2024
   Job 56463665 finished for user Gillian.Petro in partition hera with exit code 0:0
   _______________________________________________________________
   End Epilogue Fri Mar  1 22:38:34 UTC 2024

The experiment has successfully completed when all tasks say SUCCEEDED under STATE. Other potential statuses are: QUEUED, SUBMITTING, RUNNING, DEAD. Users may view the ``slurm-########.out`` files to determine why an task may have failed. 

Check Experiment Output
=========================

As the experiment progresses, it will create an experiment directory in ``$LANDDAROOT/landda_expts/EXP_NAME`` to hold experiment output. (Note that ``$EXP_NAME`` was set in ``land_analysis.yaml``.)

.. COMMENT: Edit from here down!

Check for the background and analysis files in the experiment directory:

.. code-block:: console

   ls -l $LANDDAROOT/landda_expts/EXP_NAME/DA_<data_source>_test/mem000/restarts/<vector/tile>``

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
