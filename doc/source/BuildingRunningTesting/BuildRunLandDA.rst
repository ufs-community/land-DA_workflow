.. _BuildRunLandDA:

***********************************************************
Running the Land DA Workflow (Ursa/Orion/Hercules/Gaea-C6)
***********************************************************

This chapter provides instructions for building and running the Unified Forecast System (:term:`UFS`) Land DA System using a Jan. 19-20, 2025 00z sample :term:`LND` :term:`warmstart` case using :term:`ERA5` and :term:`IMS` data and the 3D-Var algorithm with the UFS Noah-MP land component and data atmosphere (:term:`DATM`) component.

.. include:: ../doc-snippets/gcblizzard-desc.rst

.. attention::
   
   These steps are designed for use on :ref:`Level 1 <LevelsOfSupport>` systems (e.g., Ursa, Hercules) and may require significant changes on other systems. It is recommended that users on other systems run the containerized version of Land DA. Users may reference :numref:`Chapter %s: Containerized Land DA Workflow <Container>` for instructions.

.. _create-dir:

Create a Working Directory
*****************************

.. include:: ../doc-snippets/create-work-dir.rst

.. _GetCode:

Get Code
***********

Clone the Land DA workflow repository |latestr| release:

.. code-block:: console

   git clone -b release/public-v3.0.0 --recursive https://github.com/ufs-community/land-DA_workflow.git

.. attention:: 

   When working with a release branch, be sure to follow instructions in the release branch documentation. View the `v3.0.0 release documentation here <https://land-da-workflow.readthedocs.io/en/release-public-v3.0.0/>`_. When working with the ``develop`` branch, the `develop branch documentation <https://land-da-workflow.readthedocs.io/en/develop/>`_ is most appropriate. 


To clone the ``develop`` branch instead, run:

.. code-block:: console

   git clone -b develop --recursive https://github.com/ufs-community/land-DA_workflow.git

.. _build-land-da:

Build the Land DA System
***************************

#. Navigate to the ``sorc`` directory.

   .. code-block:: console

      cd ${BASEDIR}/land-DA_workflow/sorc

#. Run the build script ``app_build.sh``:

   .. code-block:: console

      ./app_build.sh

   Users may need to press the ``Enter`` key to advance the build once the list of currently loaded modules appears. 
   If the code successfully compiles, the console output should include:
   
   .. code-block:: console

      [100%] Completed 'ufs_model.fd'
      [100%] Built target ufs_model.fd
      ...
      exit 0
   
   Additionally, the ``exec`` directory will contain the following executables: 

      * ``apply_incr.exe``
      * ``calcfIMS.exe``
      * ``tile2tile_converter.exe``
      * ``ufs_model``

.. _config-wflow:

Configure an Experiment
*************************

Several sample experiment configurations come with the Land DA System. Although this chapter outlines how to run the ``config.LND.era5.3dvar.ims.DA-fcst.warmstart.yaml`` case, the following cases are available for use in the ``land-DA_workflow/parm/config_samples`` directory:

* ``config.ATML.3dvar.ghcn.DA-fcst.coldstart.yaml``
* ``config.ATML.3dvar.ghcn.DA-fcst.warmstart.yaml``
* ``config.LND.bkg_ext_src_test.yaml``
* ``config.LND.era5.3dvar.ims.DA-fcst.warmstart.yaml``
* ``config.LND.era5.letkfoi.ghcn.DA-fcst.coldstart.yaml``
* ``config.LND.era5.letkfoi.smap.free-fcst.warmstart.yaml``
* ``config.LND.era5.letkfoi.smops.free-fcst.coldstart.yaml``
* ``config.LND.gswp3.3dvar.ghcn.DA-fcst.coldstart.yaml``
* ``config.LND.gswp3.letkfoi.ghcn.DA-fcst.warmstart.yaml``

The sample configuration files are named based on their features: 

* Configuration (:term:`LND` or :term:`ATML`)
* Atmospheric forcing data (``gswp3`` or ``era5``) --- if any
* :term:`DA <DA>` algorithm (``letkfoi`` or ``3dvar``)
* Snow depth data source (:term:`IMS`, :term:`GHCN`, :term:`SFCSNO`) or soil moisture data source (:term:`SMAP`, :term:`SMOPS`)
* Type of forecast (i.e., :term:`DA-fcst` or :term:`free-fcst`)
* Forecast start (i.e., :term:`warmstart` or :term:`coldstart`)

Users are encouraged to explore and modify the options available! 

.. _load-env:

Load the Workflow Environment
===============================

To load the workflow environment, run: 

.. include:: ../doc-snippets/load-env.rst

.. _configure-expt:

Modify the Workflow Configuration YAML
========================================

Copy the experiment settings into ``config.yaml``:

.. code-block:: console

   cd ${BASEDIR}/land-DA_workflow/parm
   cp config_samples/config.LND.era5.3dvar.ims.DA-fcst.warmstart.yaml config.yaml

Users will need to configure the ``account`` variable in ``config.yaml`` and choose an ``EXP_CASE_NAME`` if a different name for the experiment is desired: 

   * ``ACCOUNT:`` A valid account name. Most NOAA :term:`RDHPCS` systems require a valid account name; other systems may not (in which case, any value will do).
   * ``EXP_CASE_NAME:`` This variable can be changed to any name the user wants (but note that whitespace and some punctuation characters are not allowed). However, the best names will indicate useful information about the experiment. This documentation uses ``lnd_era5_3dvar_ims_00`` to indicate that it is an ERA5-LND case using 3D-Var data assimilation of IMS observations. 

.. note::

   To determine an appropriate ``ACCOUNT`` field for Level 1 systems that use the Slurm job scheduler, run ``saccount_params``. On other systems, running ``groups`` will return a list of projects that the user has permissions for. Not all listed projects/groups have an HPC allocation, but those that do are potentially valid account names. 

Users may configure other elements of an experiment in ``config.yaml`` if desired. For example, users may wish to alter ``DATE_FIRST_CYCLE``, ``DATE_LAST_CYCLE``, and/or ``DATE_CYCLE_FREQ_HR`` to indicate a different start cycle, end cycle, and increment. Users may also wish to change the DA algorithm from ``3dvar`` to ``letkf-oi`` via the ``JEDI_ALGORITHM`` variable. Users who wish to run a more complex experiment may change the values in ``config.yaml`` using information from Sections :numref:`%s: Workflow Configuration Parameters <ConfigWorkflow>`, :numref:`%s: I/O for the Land DA System <IO>`, and :numref:`%s: JEDI DA System <DASystem>`. 

.. attention:: 

   When regenerating an experiment from the same or similar ``config.yaml`` file, if the ``EXP_CASE_NAME`` remains the same, the old experiment directory with that name will be renamed with the ``*_old`` suffix, and the new experiment directory will use ``EXP_CASE_NAME``. However, the ``envir`` directory will **NOT** be regenerated unless the ``envir`` parameter is given a new name. If it keeps the same name, the previous ``ptmp/<envir>`` directory and everything in it will remain (rather than being renamed), and the experiment will continue from where it left off using the files from the previous directory. This can be helpful in certain cases but detrimental in others, so users need to make a conscious choice based on their use case. 

.. _GetData:

Data
------

:numref:`Table %s <Level1Data>` shows the locations of pre-staged data on NOAA :term:`RDHPCS` (e.g., Ursa, Hercules). These data locations are already linked to the Land DA System during the build but are provided here for informational purposes. 
   
.. _Level1Data:

.. list-table:: Level 1 RDHPCS Data
   :header-rows: 1

   * - Platform
     - Data Location
   * - Hercules & Orion
     - /work/noaa/epic/UFS_Land-DA_v3.0/inputs
   * - Gaea-C6
     - /gpfs/f6/bil-fire8/world-shared/UFS_Land-DA_v3.0/inputs
   * - Ursa
     - /scratch3/NAGAPE/epic/UFS_Land-DA_v3.0/inputs
   

Users who have difficulty accessing the data on Ursa, Orion, Hercules, or Gaea-C6 may download it according to the instructions in :numref:`Section %s <GetDataC>`. Its subdirectories are soft-linked to the ``land-DA_workflow/fix`` directory by the build script (``sorc/app_build.sh``); when downloading new data, it should be placed in or linked to the ``fix`` directory.

.. _generate-wflow:

Set Up the Workflow
==============================

Generate the experiment directory by running: 

.. code-block:: console

   ./setup_wflow_env.py -p=<platform>

where ``<platform>`` is ``ursa``, ``orion``, ``hercules``, or ``gaeac6``.

If the command runs without issue, this script will print override messages, experiment details, and "Schema validation succeeded" messages to the console, similar to the following excerpts: 

.. code-block:: console

   Python Log Level= str: INFO, attr: 20
   INFO::/scratch3/NAGAPE/epic/User.Name/ursa/landda/land-DA_workflow/parm/./setup_wflow_env.py::L35:: Current directory (PARMdir): /scratch3/NAGAPE/epic/User.Name/ursa/landda/land-DA_workflow/parm 
   INFO::/scratch3/NAGAPE/epic/User.Name/ursa/landda/land-DA_workflow/parm/./setup_wflow_env.py::L37:: Home directory (HOMEdir): /scratch3/NAGAPE/epic/User.Name/ursa/landda/land-DA_workflow 
   INFO::/scratch3/NAGAPE/epic/User.Name/ursa/landda/land-DA_workflow/parm/./setup_wflow_env.py::L39:: Experimental base directory (exp_basedir): /scratch3/NAGAPE/epic/User.Name/ursa/landda 
   INFO::/scratch3/NAGAPE/epic/User.Name/ursa/landda/land-DA_workflow/parm/./setup_wflow_env.py::L220:: Experimental case directory /scratch3/NAGAPE/epic/User.Name/ursa/landda/exp_case/lnd_era5_3dvar_ims_00 has been created.
   INFO::/scratch3/NAGAPE/epic/User.Name/ursa/landda/land-DA_workflow/parm/./setup_wflow_env.py::L227:: Rocoto YAML template: /scratch3/NAGAPE/epic/User.Name/ursa/landda/land-DA_workflow/parm/templates/template.land_analysis.yaml
   **************************************************
   Overriding              ACCOUNT = epic
   Overriding                  APP = LND
   Overriding           ATMOS_FORC = era5
   Overriding      ATM_IO_LAYOUT_X = 1
   Overriding      ATM_IO_LAYOUT_Y = 1
   ...
   Overriding  nprocs_forecast_atm = 12
   Overriding  nprocs_forecast_lnd = 12
   Overriding      nprocs_per_node = 26
   Overriding    partition_default = u1-compute
   Overriding        queue_default = batch
   Overriding               res_p1 = 97
   **************************************************
                    res_p1: 97
           ATM_IO_LAYOUT_X: 1
                       APP: LND
                 OBS_SMOPS: NO
       DO_BKG_ANAL_EXT_SRC: NO
   ...
           nprocs_forecast: 26
                 DT_RUNSEQ: 3600
                    FCSTHR: 24
                CCPP_SUITE: FV3_GFS_v17_p8_ugwpv1
       nprocs_forecast_lnd: 12
   CUSTOM_JEDI_CONFIG_FLAG: NO
   INFO::/scratch3/NAGAPE/epic/ufs-conda/miniconda3/envs/ufs-land-da-wflow-i11/lib/python3.11/site-packages/uwtools/config/validator.py::L81::Schema validation succeeded for Rocoto config
   INFO::/scratch3/NAGAPE/epic/ufs-conda/miniconda3/envs/ufs-land-da-wflow-i11/lib/python3.11/site-packages/uwtools/rocoto.py::L81::Schema validation succeeded for Rocoto XML

The setup script (``./setup_wflow_env.py``) will create an experiment directory, located by default at ``${BASEDIR}/exp_case/${EXP_CASE_NAME}/``. It will populate this directory with the experiment configuration file (``land_analysis.yaml``), the workflow XML file (``land_analysis.xml``), and the workflow launch script (``launch_rocoto_wflow.sh``), as well as several directories described in :numref:`Table %s <expt_dir>` below. 

.. _expt_dir:

.. list-table:: Initial Experiment Directory
   :header-rows: 1

   * - File/Directory Name
     - Description
   * - ``automate_launch_script.py``
     - Script to automate running of the launch script (``launch_rocoto_wflow.sh``)
   * - ``com_dir``
     - Symlink to the ``ptmp/${envir}/com/landda/v3.0.0`` directory, which contains output files for each cycle
   * - ``land_analysis.yaml``
     - Combines information from the user's ``config.yaml`` file with machine-specific values and calculated values that will be used in the experiment 
   * - ``land_analysis.xml``
     - Workflow XML file used by the Rocoto workflow manager to determine which tasks (or "jobs") to submit to the batch system and when to submit them (e.g., when task dependencies are satisfied) 
   * - ``launch_rocoto_wflow.sh``
     - Workflow launch script
   * - ``log_dir``
     - Symlink to the directory containing log files for the Rocoto workflow (``ptmp/${envir}/com/output/logs``)
   * - ``tmp_dir``
     - Symlink to the ``ptmp/${envir}/tmp`` directory, which contains the working directory and temporary/intermediate files

For a deeper understanding of the ``setup_wflow_env.py`` script, see :numref:`Figure %s <setup-wflow-script>`.

Run the Experiment
********************

To run the experiment, users can automate job submission or submit tasks manually via ``rocotorun``. 

.. _wflow-overview:

Workflow Overview
==================

.. include:: ../doc-snippets/wflow-task-table.rst

.. _automated-run:

Automated Run
==================

Via Crontab
-------------
To automate task submission via crontab, users must be on a system where :term:`cron` is available. On Orion, cron is only available on the orion-login-1 node, and on Hercules, it is only available on hercules-login-1, so users will need to work on those nodes when running cron jobs on Orion/Hercules.

.. include:: ../doc-snippets/automated-run.rst

To check the status of the experiment, see :numref:`Section %s <VerifySuccess>` on tracking experiment progress.

Via ``automate_launch_script.py``
----------------------------------

To automate task submission using ``automate_launch_script.py``, simply run the script:

.. code-block:: console 

   ./automate_launch_script.py

The console will output progress messages every 10 seconds by default: 

.. code-block:: console 
   
   Running ./launch_rocoto_wflow.sh ...
    Cycles: 0 out of 2 completed.
    Detected wflow_status = IN PROGRESS
    Waiting 10 seconds before next run ...
   
   ...

   Running ./launch_rocoto_wflow.sh ...
    Cycles: 1 out of 2 completed.
    Detected wflow_status = IN PROGRESS
    Waiting 10 seconds before next run ...

   Running ./launch_rocoto_wflow.sh ...
    Cycles: 2 out of 2 completed.
    Detected wflow_status = SUCCESS

    !!! ===== Workflow completed successfully. Stopping ===== !!!

Users can change how often the script relaunches by adding the ``-i`` argument. For example, to run the workflow launch script every 15 seconds, users would run: 

.. code-block:: console

   ./automate_launch_script.py -i=15

To check the status of the experiment, see :numref:`Section %s <VerifySuccess>` on tracking experiment progress.

.. _manual-run:

Manual Submission
==================

.. include:: ../doc-snippets/manual-run.rst

Details on checking experiment status are provided in the :ref:`next section <VerifySuccess>`.

.. _VerifySuccess:

Track Progress
=================

.. include:: ../doc-snippets/track-progress.rst

.. _check-output:

Check Experiment Output
=========================

.. include:: ../doc-snippets/check-output.rst

.. _plotting:

Plotting Results
-----------------

.. include:: ../doc-snippets/plotting.rst