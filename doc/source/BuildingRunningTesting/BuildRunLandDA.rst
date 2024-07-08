.. _BuildRunLandDA:

************************************
Land DA Workflow (Hera & Orion)
************************************

This chapter provides instructions for building and running basic Land DA cases for the Unified Forecast System (:term:`UFS`) Land DA System. Users can choose between two options: 

   * A Dec. 21-22, 2019 00z sample case using ERA5 data with the UFS Land Driver (``land_analysis_era5_<machine>``)
   * A Jan. 3-4, 2000 00z sample case using GSWP3 data with the UFS Noah-MP land component (``land_analysis_gswp3_<machine>``). 

Land DA now includes cycling/restart capabilities to run a multi-day experiment. 

.. COMMENT: Remove land driver info?

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

.. _GetCode:

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
   cp land_analysis_<platform>.yaml land_analysis.yaml

where ``<platform>`` is ``hera`` or ``orion``.
   
Users will need to configure certain elements of their experiment in ``land_analysis.yaml``: 

   * ``MACHINE:`` A valid machine name (i.e., ``hera`` or ``orion``)
   * ``ACCOUNT:`` A valid account name. Hera, Orion, and most NOAA RDHPCS systems require a valid account name; other systems may not
   * ``EXP_BASEDIR:`` The full path to the directory where land-DA_workflow was cloned (i.e., ``$LANDDAROOT``)
   * ``JEDI_INSTALL:`` The full path to the system's ``jedi-bundle`` installation
   * ``FORCING:`` Forcing options; ``gswp3`` or ``era5``
   * ``cycledef/spec:`` Cycle specification

.. note::

   To determine an appropriate ``ACCOUNT`` field for Level 1 systems that use the Slurm job scheduler, run ``saccount_params``. On other systems, running ``groups`` will return a list of projects that the user has permissions for. Not all listed projects/groups have an HPC allocation, but those that do are potentially valid account names. 

Users may configure other elements of an experiment in ``land_analysis.yaml`` if desired. The ``land_analysis_*`` files contain reasonable default values for running a Land DA experiment. Users who wish to run a more complex experiment may change the values in these files and the files they reference using information in Sections :numref:`%s <Model>` & :numref:`%s <DASystem>`. 

.. _GetData:

Data
------

:numref:`Table %s <Level1Data>` shows the locations of pre-staged data on NOAA :term:`RDHPCS` (i.e., Hera and Orion). 
   
.. _Level1Data:

.. table:: Level 1 RDHPCS Data

   +-----------+--------------------------------------------------+
   | Platform  | Data Location                                    |
   +===========+==================================================+
   | Hera      | /scratch2/NAGAPE/epic/UFS_Land-DA_Dev/inputs     |
   +-----------+--------------------------------------------------+
   | Orion     | /work/noaa/epic/UFS_Land-DA_Dev/inputs           |
   +-----------+--------------------------------------------------+

Users who have difficulty accessing the data on Hera or Orion may download it according to the instructions in :numref:`Section %s <GetDataC>`. Its sub-directories are soft-linked to the ``fix`` directory of the land-DA workflow by the build script ``sorc/app_build.sh``.

.. _generate-wflow:

Generate the Rocoto XML File
==============================

Generate the workflow with ``uwtools`` by running: 

.. code-block:: console

   uw rocoto realize --input-file land_analysis.yaml --output-file land_analysis.xml

If the command runs without problems, ``uwtools`` will output a "0 errors found" message similar to the following: 

.. code-block:: console

   [2024-03-01T20:36:03]     INFO 0 UW schema-validation errors found
   [2024-03-01T20:36:03]     INFO 0 Rocoto validation errors found

Run the Experiment
********************

.. _wflow-overview:

Workflow Overview
==================

Each Land DA experiment includes multiple tasks that must be run in order to satisfy the dependencies of later tasks. These tasks are housed in the :term:`J-job <j-jobs>` scripts contained in the ``jobs`` directory. 

.. list-table:: *J-job Tasks in the Land DA Workflow*
   :header-rows: 1

   * - J-job Task
     - Description
   * - JLANDDA_PREP_OBS
     - Sets up the observation data files
   * - JLANDDA_PRE_ANAL
     - Transfers the snow data from the restart files to the surface data files
   * - JLANDDA_ANALYSIS
     - Runs :term:`JEDI` and adds the increment to the surface data files
   * - JLANDDA_POST_ANAL
     - Transfers the JEDI result from the surface data files to the restart files
   * - JLANDDA_PLOT_STATS
     - Plots the JEDI result (scatter/histogram)
   * - JLANDDA_FORECAST
     - Runs the forecast model

Users may run these tasks :ref:`using the Rocoto workflow manager <run-w-rocoto>` or :ref:`using a batch script <run-batch-script>`. 

.. _run-w-rocoto:

Run With Rocoto
=================

.. note:: 

   Users who do not have Rocoto installed on their system can view :numref:`Section %s: Run Without Rocoto <run-batch-script>`.

To run the experiment, users can automate job submission via :term:`crontab` or submit tasks manually via ``rocotorun``. 

Automated Run
---------------

To automate task submission, users must be on a system where :term:`cron` is available. On Orion, cron is only available on the orion-login-1 node, so users will need to work on that node when running cron jobs on Orion.

.. code-block:: console

   cd parm
   conda deactivate        # optional
   ./launch_rocoto_wflow.sh add

To check the status of the experiment, see :numref:`Section %s <VerifySuccess>` on tracking experiment progress.

Manual Submission
-------------------

To run the experiment, issue a ``rocotorun`` command from the ``parm`` directory: 

.. code-block:: console

   rocotorun -w land_analysis.xml -d land_analysis.db

Users will need to issue the ``rocotorun`` command multiple times. The tasks must be run in order, and ``rocotorun`` initiates the next task once its dependencies have completed successfully. Note that the status table printed by ``rocotostat`` only updates after each ``rocotorun`` command. Details on checking experiment status are provided in the :ref:`next section <VerifySuccess>`.

.. _VerifySuccess:

Track Experiment Status
-------------------------

To view the experiment status, run: 

.. code-block:: console

   rocotostat -w land_analysis.xml -d land_analysis.db

If ``rocotorun`` was successful, the ``rocotostat`` command will print a status report to the console. For example:

.. code-block:: console

   CYCLE                TASK                       JOBID        STATE   EXIT STATUS   TRIES   DURATION
   =========================================================================================================
   200001030000     prep_obs                    61746064       QUEUED             -       1        0.0
   200001030000     pre_anal   druby://10.184.3.62:41973   SUBMITTING             -       1        0.0
   200001030000     analysis                           -            -             -       -          -
   200001030000    post_anal                           -            -             -       -          -
   200001030000   plot_stats                           -            -             -       -          -
   200001030000     forecast                           -            -             -       -          -
   ================================================================================================================================
   200001040000     prep_obs   druby://10.184.3.62:41973   SUBMITTING             -       1        0.0
   200001040000     pre_anal                           -            -             -       -          -
   200001040000     analysis                           -            -             -       -          -
   200001040000    post_anal                           -            -             -       -          -
   200001040000   plot_stats                           -            -             -       -          -
   200001040000     forecast                           -            -             -       -          -

Users will need to issue the ``rocotorun`` command multiple times. The tasks must run in order, and ``rocotorun`` initiates the next task once its dependencies have completed successfully. Note that the status table printed by ``rocotostat`` only updates after each ``rocotorun`` command. For each task, a log file is generated. These files are stored in ``$LANDDAROOT/com/output/logs/run_<forcing>``, where ``<forcing>`` is either ``gswp3`` or ``era5``. 

The experiment has successfully completed when all tasks say SUCCEEDED under STATE. Other potential statuses are: QUEUED, SUBMITTING, RUNNING, and DEAD. Users may view the log files to determine why a task may have failed.

.. COMMENT: Where are log files now?!

.. _run-batch-script:

Run Without Rocoto
--------------------

Users may choose not to run the workflow with uwtools and Rocoto for a non-cycled run. To run the :term:`J-jobs` scripts in the ``jobs`` directory, navigate to the ``parm`` directory and edit ``run_without_rocoto.sh`` (e.g., using vim or preferred command line editor). Users will likely need to change the ``MACHINE``, ``ACCOUNT``, and ``EXP_BASEDIR`` variables to match their system. Then, run ``run_without_rocoto.sh``:

.. code-block:: console

   cd $LANDDAROOT/land-DA_workflow/parm
   sbatch run_without_rocoto.sh

Check Experiment Output
=========================

As the experiment progresses, it will generate a number of directories to hold intermediate and output files. The directory structure for those files and directories appears below:

.. code-block:: console

   $LANDDAROOT: Base directory
    ├── land-DA_workflow(<CYCLEDIR>): Home directory of the land DA workflow
    ├── ptmp (<PTMP>)
    │     └── test (<envir>)
    │           └── com
    │                ├── landda (<NET>)
    │                │     └── vX.Y.Z (<model_ver>)
    │                │           └── landda.YYYYMMDD (<RUN>.<PDY>): Directory containing the output files
    │                └── output
    │                      └── logs
    │                            └── run_<forcing> (<LOGDIR>): Directory containing the log file of the Rocoto workflow
    └── tmp (<DATAROOT>)
         ├── <jobid> (<DATA>): Working directory
         └── DATA_SHARE
               ├── YYYYMMDD (<PDY>): Directory containing the intermediate or temporary files
               └── DATA_RESTART: Directory containing the soft-links to the restart files for the next cycles

``<forcing>`` refers to the type of forcing data used (``gswp3`` or ``era5``). Each variable in parentheses and angle brackets (e.g., ``(<VAR>)``) is the name for the directory defined in the file ``land_analysis.yaml``. In the future, this directory structure will be further modified to meet the :nco:`NCO Implementation Standards<>`.

Check for the output files for each cycle in the experiment directory:

.. code-block:: console

   ls -l $LANDDAROOT/ptmp/test/com/landda/v1.2.1/landda.YYYYMMDD

where ``YYYYMMDD`` is the cycle date. The experiment should generate several restart files. 

Additionally, in the ``plot`` subdirectory, users will find images depicting the results of the ``analysis`` task for each cycle as a scatter plot (``hofx_oma_YYYMMDD_scatter.png``) and as a histogram (``hofx_oma_YYYYMMDD_histogram.png``). The scatter plot is named OBS-ANA (i.e., Observation Minus Analysis [OMA]), and it depicts a map of snow depth results. Blue points indicate locations where the observed values are less than the analysis values, and red points indicate locations where the observed values are greater than the analysis values. The histogram plots *observation - analysis* values, with the difference in snow depth on the y-axis. 
