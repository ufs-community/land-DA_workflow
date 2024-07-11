.. _ConfigWorkflow:

***************************************************
Available Workflow Configuration Parameters
***************************************************

To run the Land DA System, users must create an experiment configuration file (named ``land_analysis.yaml`` by default). This file contains experiment-specific information, such as forecast/cycle dates, grid and physics suite choices, data directories, and other relevant settings. To help the user, two sample ``land_analysis_<machine>.yaml`` configuration files have been included in the ``parm`` directory for use on Hera and Orion. They contain reasonable experiment default values that work on those machines. The content of these files can be copied into ``land_analysis.yaml`` and used as the starting point from which to generate a variety of experiment configurations for Land DA. 

The following is a list of the parameters in the ``land_analysis_<machine>.yaml`` files. For each parameter, the default value and a brief description are provided. 

Workflow Attributes (``attrs:``)
=================================

Attributes pertaining to the overall workflow are defined in the ``attrs:`` section under ``workflow:``. For example: 

.. code-block:: console 

   workflow:
     attrs:
       realtime: false
       scheduler: slurm
       cyclethrottle: 24
       taskthrottle: 24

``realtime:`` (Default: false)
   Indicates whether it is a realtime run (true) or not (false). Valid values: ``true`` | ``false``

``scheduler:`` (Default: slurm)
   The job scheduler to use on the specified machine. Valid values: ``"slurm"`` | ``"pbspro"`` | ``"lsf"`` | ``"lsfcray"`` | ``"none"``

.. COMMENT: Check valid values! 

``cyclethrottle:`` (Default: 24)
   The number of cycles that can be active at one time. Valid values: Integer values >= 0.

``taskthrottle:`` (Default: 24)
   The number of tasks that can be active at one time. Valid values: Integer values >= 0.


Workflow Cycle Definition (``cycledef``)
==========================================

Cycling information is defined in the ``cycledef:`` section under ``workflow:``. Each cycle definition starts with a ``-`` and has information on cycle attributes (``attrs:``) and a cycle specification (``spec:``). For example: 

.. code-block:: console 

   workflow:
     cycledef:
       - attrs:
           group: cycled
         spec: 201912210000 201912220000 24:00:00

``attrs:``
   Attributes of ``cycledef``. Includes ``group:`` but may also include ``activation_offset:``.

   ``group:``
      The group attribute allows users to assign a set of cycles to a particular group. The group tag can later be used to control which tasks are run for which cycles. See the :rocoto:`Rocoto Documentation <>` for more information. 

``spec:`` 
   The cycle is defined using the "start stop step" method, with the cycle start date listed first in YYYMMDDHHmm format, followed by the end date and then the step in HH:mm:SS format (e.g., ``201912210000 201912220000 24:00:00``).

Workflow Entities
===================

Entities are constants that can be referred to throughout the workflow using the ``&`` prefix and ``;`` suffix (e.g., ``&MACHINE;``) to avoid defining the same constants repetitively in each workflow task. For example, in ``land_analysis_orion.yaml``, the following entities are defined: 

.. code-block:: console 

   entities:
     MACHINE: "orion"
     SCHED: "slurm"
     ACCOUNT: "epic"
     EXP_NAME: "LETKF"
     EXP_BASEDIR: "/work/noaa/epic/{USER}/landda_test"
     JEDI_INSTALL: "/work/noaa/epic/UFS_Land-DA_Dev/jedi_v7_stack1.6"
     WARMSTART_DIR: "/work/noaa/epic/UFS_Land-DA_Dev/inputs/DATA_RESTART"
     FORCING: "gswp3"
     RES: "96"
     FCSTHR: "24"
     NPROCS_ANALYSIS: "6"
     NPROCS_FORECAST: "7"
     OBSDIR: ""
     OBSDIR_SUBDIR: ""
     OBS_TYPES: "GHCN"
     DAtype: "letkfoi_snow"
     SNOWDEPTHVAR: "snwdph"
     TSTUB: "oro_C96.mx100"
     NET: "landda"
     envir: "test"
     model_ver: "v1.2.1"
     RUN: "landda"
     HOMElandda: "&EXP_BASEDIR;/land-DA_workflow"
     PTMP: "&EXP_BASEDIR;/ptmp"
     COMROOT: "&PTMP;/&envir;/com"
     DATAROOT: "&PTMP;/&envir;/tmp"
     KEEPDATA: "YES"
     LOGDIR: "&COMROOT;/output/logs/run_&FORCING;"
     LOGFN_SUFFIX: "<cyclestr>_@Y@m@d@H.log</cyclestr>"
     PATHRT: "&EXP_BASEDIR;"
     PDY:  "<cyclestr>@Y@m@d</cyclestr>"
     cyc: "<cyclestr>@H</cyclestr>"
     DATADEP_FILE1: "<cyclestr>&WARMSTART_DIR;/ufs_land_restart.@Y-@m-@d_@H-00-00.tile1.nc</cyclestr>"
     DATADEP_FILE2: "<cyclestr>&WARMSTART_DIR;/ufs_land_restart.@Y-@m-@d_@H-00-00.nc</cyclestr>"
     DATADEP_FILE3: "<cyclestr>&DATAROOT;/DATA_SHARE/RESTART/ufs_land_restart.@Y-@m-@d_@H-00-00.tile1.nc</cyclestr>"
     DATADEP_FILE4: "<cyclestr>&DATAROOT;/DATA_SHARE/RESTART/ufs_land_restart.@Y-@m-@d_@H-00-00.nc</cyclestr>"

.. note:: 

   When two defaults are listed, one is the default on Hera, and one is the default on Orion, depending on ``land_analysis_<machine>.yaml`` file used. The default on Hera is listed first, followed by the default on Orion. 

``MACHINE:`` (Default: "hera" or "orion")
   The machine (a.k.a. platform or system) on which the workflow will run. Currently supported platforms are listed in :numref:`Section %s <LevelsOfSupport>`. Valid values: ``"hera"`` | ``"orion"`` | ``"singularity"``

.. COMMENT: Check Singularity or NOAA Cloud or anything?

``SCHED:`` (Default: "slurm")
   The job scheduler to use (e.g., Slurm) on the specified ``MACHINE``. Valid values: ``"slurm"`` | ``"pbspro"`` | ``"lsf"`` | ``"lsfcray"`` | ``"none"``

.. COMMENT: Check valid values! Also, isn't this a duplicate of "scheduler:"?

``ACCOUNT:`` (Default: "epic")
   The account under which users submit jobs to the queue on the specified ``MACHINE``. To determine an appropriate ``ACCOUNT`` field on a system with a Slurm job scheduler, users may run the ``saccount_params`` command to display account details. On other systems, users may run the ``groups`` command, which will return a list of projects that the user has permissions for. Not all of the listed projects/groups have an HPC allocation, but those that do are potentially valid account names. 

``EXP_NAME:`` (Default: "LETKF")
   Placeholder --- currently not used in workflow. 

``EXP_BASEDIR:`` (Default: "/scratch2/NAGAPE/epic/{USER}/landda_test" or "/work/noaa/epic/{USER}/landda_test")
   The full path to the directory that ``land-DA_workflow`` was cloned into (i.e., ``$LANDDAROOT`` in the documentation).

``JEDI_INSTALL:`` (Default: "/scratch2/NAGAPE/epic/UFS_Land-DA_Dev/jedi_v7" or "/work/noaa/epic/UFS_Land-DA_Dev/jedi_v7_stack1.6")
   The path to the JEDI |skylabv| installation. 

``WARMSTART_DIR:`` (Default: "/scratch2/NAGAPE/epic/UFS_Land-DA_Dev/inputs/DATA_RESTART" or "/work/noaa/epic/UFS_Land-DA_Dev/inputs/DATA_RESTART")
   The path to restart files for a warmstart experiment. 

``FORCING:`` (Default: "gswp3")
   Type of atmospheric forcing data used. Valid values: "gswp3" or "era5"

``RES:`` (Default: "96")
   Resolution of FV3 grid. Currently, only C96 resolution is supported. 

``FCSTHR:`` (Default: "24")
   Specifies the length of each forecast in hours.

``NPROCS_ANALYSIS:`` (Default: "6")
   Number of processors for the analysis task. 

.. COMMENT: Check this!

``NPROCS_FORECAST:`` (Default: "7")
   Number of processors for the forecast task. 

.. COMMENT: Check this!

``OBSDIR:`` (Default: "")
   The path to the directory where ______??? 
   .. COMMENT: Add definition here! 

``OBSDIR_SUBDIR:`` (Default: "")
.. COMMENT: Add definition!

``OBS_TYPES:`` (Default: "GHCN")
   Specifies the observation type. Format is "Obs1" "Obs2". Currently, only GHCN observation data is available. 

``DAtype:`` (Default: "letkfoi_snow")
.. COMMENT: Add definition!

``SNOWDEPTHVAR:`` (Default: "snwdph")
.. COMMENT: Add definition!

``TSTUB:`` (Default: "oro_C96.mx100")
   Specifies the file stub/name for orography files in TPATH. This file stub is named oro_C${RES} for atmosphere-only orography files and oro_C{RES}.mx100 for atmosphere and ocean orography files.

NCO Directory Structure Entities
----------------------------------

Standard environment variables are defined in the NCEP Central Operations :nco:`WCOSS Implementation Standards <ImplementationStandards.v11.0.0.pdf>` document. These variables are used in forming the path to various directories containing input, output, and workflow files. For a visual aid, see the :ref:`Land DA Directory Structure Diagram <land-da-dir-structure>`. The variables are defined in the WCOSS Implementation Standards document (pp. 4-5) as follows:

``HOMElandda:`` (Default: "&EXP_BASEDIR;/land-DA_workflow")
   The location of the :github:`land-DA_workflow` clone. 

``PTMP:`` (Default: "&EXP_BASEDIR;/ptmp")
   User-defined path to the ``com``-type directories.

``envir:`` (Default: "test")
   The run environment. Set to “test” during the initial testing phase, “para” when running in parallel (on a schedule), and “prod” in production. 

``COMROOT:`` (Default: "&PTMP;/&envir;/com")
   ``com`` root directory, which contains input/output data on current system. 

``NET:`` (Default: "landda")
   Model name (first level of ``com`` directory structure)

``model_ver:`` (Default: "v1.2.1")
   Version number of package in three digits (second level of ``com`` directory)

``RUN:`` (Default: "landda")
   Name of model run (third level of com directory structure). In general, same as ${NET}.

``DATAROOT:`` (Default: "&PTMP;/&envir;/tmp")

.. COMMENT: Add definition!


``KEEPDATA:`` (Default: "YES")
   Flag to keep data ("YES") or not ("NO").

   .. COMMENT: Check definition!

``LOGDIR:`` (Default: "&COMROOT;/output/logs/run_&FORCING;")
   Path to the log file directory. 

``LOGFN_SUFFIX:`` (Default: "<cyclestr>_@Y@m@d@H.log</cyclestr>")
.. COMMENT: Add definition!

``PATHRT:`` (Default: "&EXP_BASEDIR;")
.. COMMENT: Add definition!

``PDY:``  (Default: "<cyclestr>@Y@m@d</cyclestr>")
   Date in YYYYMMDD format.

``cyc:`` (Default: "<cyclestr>@H</cyclestr>")
   Cycle time in GMT hours, formatted HH.

``DATADEP_FILE1:`` (Default: "<cyclestr>&WARMSTART_DIR;/ufs_land_restart.@Y-@m-@d_@H-00-00.tile1.nc</cyclestr>")
``DATADEP_FILE2:`` (Default: "<cyclestr>&WARMSTART_DIR;/ufs_land_restart.@Y-@m-@d_@H-00-00.nc</cyclestr>")
``DATADEP_FILE3:`` (Default: "<cyclestr>&DATAROOT;/DATA_SHARE/RESTART/ufs_land_restart.@Y-@m-@d_@H-00-00.tile1.nc</cyclestr>")
``DATADEP_FILE4:`` (Default: "<cyclestr>&DATAROOT;/DATA_SHARE/RESTART/ufs_land_restart.@Y-@m-@d_@H-00-00.nc</cyclestr>")

.. COMMENT: Add definitions!
    
Workflow Log
==============
  log: "&LOGDIR;/workflow.log"

Workflow Tasks
================

  tasks:

Observation Preparation Task (``task_prep_obs``)
--------------------------------------------------

Parameters for the observation preparation task are set in the ``task_prep_obs:`` section of the ``land_analysis_<machine>.yaml`` file.

    task_prep_obs:
      attrs:
        cycledefs: cycled
        maxtries: 2
      envars:
        OBSDIR: "&OBSDIR;"
        OBSDIR_SUBDIR: "&OBSDIR_SUBDIR;"
        OBS_TYPES: "&OBS_TYPES;"
        MACHINE: "&MACHINE;"
        SCHED: "&SCHED;"
        ACCOUNT: "&ACCOUNT;"
        EXP_NAME: "&EXP_NAME;"
        ATMOS_FORC: "&FORCING;"
        model_ver: "&model_ver;"
        HOMElandda: "&HOMElandda;"
        COMROOT: "&COMROOT;"
        DATAROOT: "&DATAROOT;"
        KEEPDATA: "&KEEPDATA;"
        PDY: "&PDY;"
        cyc: "&cyc;"
      account: "&ACCOUNT;"
      command: '&HOMElandda;/parm/task_load_modules_run_jjob.sh "prep_obs" "&HOMElandda;" "&MACHINE;"'
      jobname: prep_obs
      cores: 1
      walltime: 00:02:00
      queue: batch
      join: "&LOGDIR;/prep_obs&LOGFN_SUFFIX;"

Pre-Analysis Task (``task_pre_anal``)
---------------------------------------

Parameters for the pre-analysis task are set in the ``task_pre_anal:`` section of the ``land_analysis_<machine>.yaml`` file.

    task_pre_anal:
      attrs:
        cycledefs: cycled
        maxtries: 2
      envars:
        MACHINE: "&MACHINE;"
        SCHED: "&SCHED;"
        ACCOUNT: "&ACCOUNT;"
        EXP_NAME: "&EXP_NAME;"
        ATMOS_FORC: "&FORCING;"
        RES: "&RES;"
        TSTUB: "&TSTUB;"
        WARMSTART_DIR: "&WARMSTART_DIR;"
        model_ver: "&model_ver;"
        RUN: "&RUN;"
        HOMElandda: "&HOMElandda;"
        COMROOT: "&COMROOT;"
        DATAROOT: "&DATAROOT;"
        KEEPDATA: "&KEEPDATA;"
        PDY: "&PDY;"
        cyc: "&cyc;"
      account: "&ACCOUNT;"
      command: '&HOMElandda;/parm/task_load_modules_run_jjob.sh "pre_anal" "&HOMElandda;" "&MACHINE;"'
      jobname: pre_anal
      cores: 1
      walltime: 00:05:00
      queue: batch
      join: "&LOGDIR;/pre_anal&LOGFN_SUFFIX;"
      dependency:
        or:
          datadep_file1:
            attrs:
              age: 5
            value: "&DATADEP_FILE1;"
          datadep_file2:
            attrs:
              age: 5
            value: "&DATADEP_FILE2;"
          datadep_file3:
            attrs:
              age: 5
            value: "&DATADEP_FILE3;"
          datadep_file4:
            attrs:
              age: 5
            value: "&DATADEP_FILE4;"

Analysis Task (``task_analysis``)
-----------------------------------

Parameters for the analysis task are set in the ``task_analysis:`` section of the ``land_analysis_<machine>.yaml`` file.

    task_analysis:
      attrs:
        cycledefs: cycled
        maxtries: 2
      envars:
        OBS_TYPES: "&OBS_TYPES;"
        MACHINE: "&MACHINE;"
        SCHED: "&SCHED;"
        ACCOUNT: "&ACCOUNT;"
        EXP_NAME: "&EXP_NAME;"
        ATMOS_FORC: "&FORCING;"
        RES: "&RES;"
        TSTUB: "&TSTUB;"
        model_ver: "&model_ver;"
        HOMElandda: "&HOMElandda;"
        COMROOT: "&COMROOT;"
        DATAROOT: "&DATAROOT;"
        KEEPDATA: "&KEEPDATA;"
        PDY: "&PDY;"
        cyc: "&cyc;"
        DAtype: "&DAtype;"
        SNOWDEPTHVAR: "&SNOWDEPTHVAR;"
        NPROCS_ANALYSIS: "&NPROCS_ANALYSIS;"
        JEDI_INSTALL: "&JEDI_INSTALL;"
      account: "&ACCOUNT;"
      command: '&HOMElandda;/parm/task_load_modules_run_jjob.sh "analysis" "&HOMElandda;" "&MACHINE;"'
      jobname: analysis
      nodes: "1:ppn=&NPROCS_ANALYSIS;"
      walltime: 00:15:00
      queue: batch
      join: "&LOGDIR;/analysis&LOGFN_SUFFIX;"
      dependency:
        taskdep:
          attrs:
            task: pre_anal

Post-Analysis Task (``task_post_anal``)
-----------------------------------------

Parameters for the post analysis task are set in the ``task_post_anal:`` section of the ``land_analysis_<machine>.yaml`` file.

    task_post_anal:
      attrs:
        cycledefs: cycled
        maxtries: 2
      envars:
        MACHINE: "&MACHINE;"
        SCHED: "&SCHED;"
        ACCOUNT: "&ACCOUNT;"
        EXP_NAME: "&EXP_NAME;"
        ATMOS_FORC: "&FORCING;"
        RES: "&RES;"
        TSTUB: "&TSTUB;"
        model_ver: "&model_ver;"
        RUN: "&RUN;"
        HOMElandda: "&HOMElandda;"
        COMROOT: "&COMROOT;"
        DATAROOT: "&DATAROOT;"
        KEEPDATA: "&KEEPDATA;"
        PDY: "&PDY;"
        cyc: "&cyc;"
        FCSTHR: "&FCSTHR;"
      account: "&ACCOUNT;"
      command: '&HOMElandda;/parm/task_load_modules_run_jjob.sh "post_anal" "&HOMElandda;" "&MACHINE;"'
      jobname: post_anal
      cores: 1
      walltime: 00:05:00
      queue: batch
      join: "&LOGDIR;/post_anal&LOGFN_SUFFIX;"
      dependency:
        taskdep:
          attrs:
            task: analysis

Plotting Task (``task_plot_stats``)
-------------------------------------

Parameters for the plotting task are set in the ``task_plot_stats:`` section of the ``land_analysis_<machine>.yaml`` file.

    task_plot_stats:
      attrs:
        cycledefs: cycled
        maxtries: 2
      envars:
        MACHINE: "&MACHINE;"
        SCHED: "&SCHED;"
        ACCOUNT: "&ACCOUNT;"
        EXP_NAME: "&EXP_NAME;"
        model_ver: "&model_ver;"
        RUN: "&RUN;"
        HOMElandda: "&HOMElandda;"
        COMROOT: "&COMROOT;"
        DATAROOT: "&DATAROOT;"
        KEEPDATA: "&KEEPDATA;"
        PDY: "&PDY;"
        cyc: "&cyc;"
      account: "&ACCOUNT;"
      command: '&HOMElandda;/parm/task_load_modules_run_jjob.sh "plot_stats" "&HOMElandda;" "&MACHINE;"'
      jobname: plot_stats
      cores: 1
      walltime: 00:10:00
      queue: batch
      join: "&LOGDIR;/plot_stats&LOGFN_SUFFIX;"
      dependency:
        taskdep:
          attrs:
            task: analysis

Forecast Task (``task_forecast``)
----------------------------------

Parameters for the forecast task are set in the ``task_forecast:`` section of the ``land_analysis_<machine>.yaml`` file.

    task_forecast:
      attrs:
        cycledefs: cycled
        maxtries: 2
      envars:
        OBS_TYPES: "&OBS_TYPES;"
        MACHINE: "&MACHINE;"
        SCHED: "&SCHED;"
        ACCOUNT: "&ACCOUNT;"
        EXP_NAME: "&EXP_NAME;"
        ATMOS_FORC: "&FORCING;"
        RES: "&RES;"
        WARMSTART_DIR: "&WARMSTART_DIR;"
        model_ver: "&model_ver;"
        HOMElandda: "&HOMElandda;"
        COMROOT: "&COMROOT;"
        DATAROOT: "&DATAROOT;"
        KEEPDATA: "&KEEPDATA;"
        LOGDIR: "&LOGDIR;"
        PDY: "&PDY;"
        cyc: "&cyc;"
        DAtype: "&DAtype;"
        FCSTHR: "&FCSTHR;"
        NPROCS_FORECAST: "&NPROCS_FORECAST;"          
      account: "&ACCOUNT;"
      command: '&HOMElandda;/parm/task_load_modules_run_jjob.sh "forecast" "&HOMElandda;" "&MACHINE;"'
      jobname: forecast
      nodes: "1:ppn=&NPROCS_FORECAST;"
      walltime: 01:00:00
      queue: batch
      join: "&LOGDIR;/forecast&LOGFN_SUFFIX;"
      dependency:
        taskdep:
          attrs:
            task: post_anal


