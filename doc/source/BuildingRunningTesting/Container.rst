.. _Container:

**********************************
Containerized Land DA Workflow
**********************************

These instructions will help users run a basic case for the Unified Forecast System (:term:`UFS`) Land Data Assimilation (DA) System using a `Singularity/Apptainer <https://apptainer.org/docs/user/latest/>`_ container. The Land DA :term:`container` packages together the Land DA System with its dependencies (e.g., :term:`spack-stack`, :term:`JEDI`), prebuilt Land-DA binaries, and provides a uniform environment in which to run the Land DA System. Normally, the details of running Earth system models will vary based on the computing platform because there are many possible combinations of operating systems, compilers, :term:`MPIs <MPI>`, and package versions available. Installation via Singularity/Apptainer container reduces this variability and allows for a smoother experience running Land DA. This approach is recommended for users not running Land DA on a supported :ref:`Level 1 <LevelsOfSupport>` system (e.g., Ursa, Hercules). 

This chapter provides instructions for running the Unified Forecast System (:term:`UFS`) Land DA System in a container using a Jan. 19-20, 2025 00z sample case. This case is a :term:`LND` :term:`warmstart` configuration that uses :term:`ERA5` atmospheric forcing data, :term:`IMS` snow depth observation data, and the 3D-Var DA algorithm. 

.. include:: ../doc-snippets/gcblizzard-desc.rst

.. attention::

   This chapter of the User's Guide should **only** be used for container builds. For non-container builds, see :numref:`Chapter %s <BuildRunLandDA>`, which describes the steps for building and running Land DA on a :ref:`Level 1 System <LevelsOfSupport>` **without** a container. 

.. _Prereqs:

Prerequisites 
**************

The containerized version of Land DA requires: 

   * `Installation of Apptainer <https://apptainer.org/docs/admin/latest/installation.html>`_ (or its predecessor, Singularity)
   * At least 26 CPU cores (may be possible to run with 13, but this has not been tested)
   * An **Intel** compiler and :term:`MPI` (available for `free here <https://www.intel.com/content/www/us/en/developer/tools/oneapi/hpc-toolkit-download.html>`_) 
   * The `Rocoto workflow manager <https://github.com/christopherwharrop/rocoto>`_
   * The `Slurm <https://slurm.schedmd.com/quickstart.html>`_ job scheduler

.. note::

   As of November 2021, the Linux-supported version of Singularity has been `renamed <https://apptainer.org/news/community-announcement-20211130/>`_ to *Apptainer*. Apptainer has maintained compatibility with Singularity, so ``singularity`` commands should work with either Singularity or Apptainer (see `compatibility details here <https://apptainer.org/docs/user/latest/singularity_compatibility.html>`_.)

.. _create-dir-c:

Create a Working Directory
*****************************

.. include:: ../doc-snippets/create-work-dir.rst

.. _GetDataC:

Get Data
***********

In order to run the Land DA System, users will need input data in the form of fix files, model forcing files, restart files, and snow depth observations for data assimilation. These files are already present on Level 1 systems (see :numref:`Section %s <Level1Data>` for details). 

Users on any system may download and untar the data from the `Land DA Data Bucket <https://registry.opendata.aws/noaa-ufs-land-da/>`_ into their ``${BASEDIR}`` directory. In the working directory, run: 

.. code-block:: console

   cd ${BASEDIR}
   wget https://noaa-ufs-land-da-pds.s3.amazonaws.com/current_land_da_release_data/v3.0.0/LandDAInputDatav3.0.0.tar.gz
   tar xvfz LandDAInputDatav3.0.0.tar.gz

.. _DownloadContainer:

Download or Build the Container
*********************************

Users can download the ``ubuntu22.04-intel-landda-release-public-v3.0.0.img`` container from the `Land DA Data Bucket <https://registry.opendata.aws/noaa-ufs-land-da/>`_ or build the Singularity container from a public Docker :term:`container` image. Downloading may be faster depending on the download speed on the user's system. 

Download the Container
========================

To download from the data bucket, users can run:

.. code-block:: console

   wget https://noaa-ufs-land-da-pds.s3.amazonaws.com/current_land_da_release_data/v3.0.0/ubuntu22.04-intel-landda-release-public-v3.0.0.img

This will download a container image named ``ubuntu22.04-intel-landda-release-public-v3.0.0.img``. Users may continue to :ref:`set up the container <SetUpContainer>`.

.. _BuildC:

Build the Container
=====================

Alternatively, users can build the container from a Docker image. (Users who have already downloaded the container may skip to the :ref:`next section <SetUpContainer>`.) Users working on systems with limited disk space in their ``/home`` directory will need to set the ``SINGULARITY_CACHEDIR`` and ``SINGULARITY_TMPDIR`` environment variables to point to a location with adequate disk space. For example:

.. code-block:: 

   export SINGULARITY_CACHEDIR=/absolute/path/to/writable/directory/cache
   export SINGULARITY_TMPDIR=/absolute/path/to/writable/directory/tmp

See detailed instructions for this in :numref:`Section %s <CloudHPC>`. Then, run: 

.. code-block:: console

   singularity build --force ubuntu22.04-intel-landda-release-public-v3.0.0.img docker://noaaepic/ubuntu22.04-intel2024.2.0-1-devel-landda:ue192-v3.0.0

This process may take several hours depending on the system. 

.. note:: 

   Some users may need to issue the ``singularity build`` command with ``sudo`` (i.e., ``sudo singularity build...``). Whether ``sudo`` is required is system-dependent. If ``sudo`` is required (or desired) for building the container, users should set the ``SINGULARITY_CACHEDIR`` and ``SINGULARITY_TMPDIR`` environment variables with ``sudo su``, as in the NOAA Cloud example from :numref:`Section %s <CloudHPC>` below.

.. _SetUpContainer:

Set Up the Container
*********************

.. attention::

   It is recommended that users establish different working directories for :term:`LND` and :term:`ATML` experiments because these experiments use different executables. This makes it impossible to run LND and ATML experiment configurations simultaneously from the same working directory. Users can circumvent this issue by creating an ``lnd`` directory for LND experiments and an ``atml`` directory for ATML experiments. Then, perform the container setup instructions in each directory. 

Create experiment variables that point to the container image (``$img``) and, if necessary, the location of the data (``$LANDDA_INPUTS``). Users only need to set the location of the data if they added it in a location other than ``${BASEDIR}``: 

.. code-block:: console

   # Set path to container
   export img=/path/to/ubuntu22.04-intel-landda-release-public-v3.0.0.img

   # Set path to data (if necessary)
   export LANDDA_INPUTS=/path/to/inputs

where ``/path/to`` is replaced by the absolute path to the location of the container and Land DA input data. 

Within the ``${BASEDIR}`` directory, copy the ``setup_container.sh`` script out of the container. 

.. code-block:: console

   singularity exec -H $PWD $img cp -r /opt/land-DA_workflow/setup_container.sh .

The ``setup_container.sh`` script should now be in the ``${BASEDIR}`` directory. Note that if previous steps included a ``sudo`` command, ``sudo`` may be required in front of this command for it to work. If for some reason, the previous command was unsuccessful, users may try a version of the following command instead: 

.. code-block:: console

   singularity exec -B /<local_base_dir>:/<container_dir> $img cp -r /opt/land-DA_workflow/setup_container.sh .

where ``<local_base_dir>`` and ``<container_dir>`` are replaced with a top-level directory on the local system and in the container, respectively. Additional directories can be bound by adding another ``-B /<local_base_dir>:/<container_dir>`` argument before the container location (``$img``). 

.. note::

   Users may convert a container ``.img`` file to a writable sandbox. This step is optional on most systems but allows users to make changes to the container if desired:

   .. code-block:: console

      singularity build --sandbox ubuntu22.04-intel-landda-release-public-v3.0.0 $img

   Sometimes binding directories with different names can cause problems. In general, it is recommended that the local base directory and the container directory have the same name. For example, if the host system's top-level directory is ``/user1234``, the user may want to convert the ``.img`` file to a writable sandbox and create a ``user1234`` directory in the sandbox to bind to. 

Next, run the ``setup_container.sh`` script with the proper arguments.

.. code-block:: console

   ./setup_container.sh -c=<compiler> -m=<mpi_implementation> -i=$img

where:

   * ``-c`` is the compiler on the user's local machine ( e.g., ``intel/2024.2.1``, ``intelmpi/2021.13``, ``intel-oneapi-compilers/2024.2.1``, ``intel/2023.2.0``)
   * ``-m`` is the :term:`MPI` on the user's local machine ( e.g., ``impi/2024.2.1``, ``intelmpi/2021.13``, ``intel-oneapi-mpi/2021.7.1``, ``cray-mpich/8.1.28``)
   * ``-i`` is the full path to the container image ( e.g., ``$BASEDIR/ubuntu22.04-intel-landda-release-public-v3.0.0.img``).

Concretely, users would run something like: 

.. code-block:: console
   
   ./setup_container.sh -c=intel/2024.2.1 -m=impi/2024.2.1 -i=$img

Running this script will print the following messages to the console:

.. code-block:: console

   Copying out land-DA_workflow from container
   Checking if LANDDA_INPUTS variable exists and linking to land-DA_workflow
   Land DA data exists, creating links
   Updating scripts files
   Updating singularity modulefiles
   Updating run related scripts
   Setup conda
   Getting the jedi test data from container
   Update experiment variables
   Creating links for exe
   Done

The user should now see the ``land-DA_workflow`` and ``jedi-bundle`` directories in the ``${BASEDIR}`` directory. 

Containers come with pre-built executables, so users may continue to the next section to configure the experiment. 

.. _ConfigureExptC:

Configure the Experiment
===========================

To configure an experiment, first load the workflow modulefiles for the container: 

.. code-block:: console

   cd land-DA_workflow
   module use modulefiles
   module load wflow_singularity

Then navigate to the ``parm`` directory and copy the desired case (e.g., ``config.LND.era5.3dvar.ims.DA-fcst.warmstart.yaml``) into ``config.yaml``: 

.. code-block:: console

   cd parm
   cp config_samples/config.<case>.yaml config.yaml

where ``<case>`` is the name of one of the sample case files in the `config_samples <https://github.com/ufs-community/land-DA_workflow/tree/develop/parm/config_samples>`_ directory. 

For example, when running the ``LND.era5.3dvar.ims.DA-fcst.warmstart`` case, run:

.. code-block:: console

   cd parm
   cp config_samples/config.LND.era5.3dvar.ims.DA-fcst.warmstart.yaml config.yaml

Users may configure elements of the experiment in ``config.yaml`` if desired. For example, users may wish to alter ``DATE_FIRST_CYCLE``, ``DATE_LAST_CYCLE``, and/or ``DATE_CYCLE_FREQ_HR`` to indicate a different start cycle, end cycle, and increment. Users may also wish to change the DA algorithm from ``3dvar`` to ``letkf`` via the ``JEDI_ALGORITHM`` variable. Users who wish to run a more complex experiment may change the values in ``config.yaml`` using information from Sections :numref:`%s: Workflow Configuration Parameters <ConfigWorkflow>`, :numref:`%s: I/O for the Land DA System <IO>`, and :numref:`%s: JEDI DA System <DASystem>`. 

.. attention:: 

   When regenerating an experiment from the same or similar ``config.yaml`` file, if the ``EXP_CASE_NAME`` remains the same, the old experiment directory with that name will be renamed with the ``*_old`` suffix, and the new experiment directory will use ``EXP_CASE_NAME``. However, the ``envir`` directory will **NOT** be regenerated unless the ``envir`` parameter is given a new name. If it keeps the same name, the previous ``ptmp/<envir>`` directory and everything in it will remain (rather than being renamed), and the experiment will continue from where it left off using the files from the previous directory. This can be helpful in certain cases but detrimental in others, so users need to make a conscious choice based on their use case. 

Generate the experiment directory by running:

.. code-block:: console

   ./setup_wflow_env.py -p=singularity

If the command runs without issue, this script will print override messages, experiment details, and "0 errors found" messages to the console, similar to the following excerpts: 

.. code-block:: console

   ubuntu@ip-10-29-93-226:~/land-DA_workflow/parm$ ./setup_wflow_env.py -p=singularity
    Python Log Level= str: INFO, attr: 20
   INFO::/contrib/${USER}/landda/land-DA_workflow/parm/./setup_wflow_env.py::L34:: Current directory (PARMdir): /contrib/Gillian.Petro/landda/land-DA_workflow/parm 
   INFO::/contrib/${USER}/landda/land-DA_workflow/parm/./setup_wflow_env.py::L36:: Home directory (HOMEdir): /contrib/Gillian.Petro/landda/land-DA_workflow 
   INFO::/contrib/${USER}/landda/land-DA_workflow/parm/./setup_wflow_env.py::L38:: Experimental base directory (exp_basedir): /contrib/Gillian.Petro/landda 
   INFO::/contrib/${USER}/landda/land-DA_workflow/parm/./setup_wflow_env.py::L168:: Experimental case directory /contrib/Gillian.Petro/landda/exp_case/lnd_era5_warmstart_00 has been created.
   INFO::/contrib/${USER}/landda/land-DA_workflow/parm/./setup_wflow_env.py::L175:: Rocoto YAML template: /contrib/Gillian.Petro/landda/land-DA_workflow/parm/templates/template.land_analysis.yaml
   **************************************************
   Overriding              ACCOUNT = epic
   Overriding                  APP = LND
   Overriding           ATMOS_FORC = era5
   ...
   Overriding        queue_default = batch
   Overriding               res_p1 = 97
   **************************************************
           DATE_FIRST_CYCLE: 2025011900
            nprocs_forecast: 26
         LND_INITIAL_ALBEDO: 0.25
               WRITE_GROUPS: 1
                  JEDI_PATH: /contrib/${USER}/landda
          MED_COUPLING_MODE: ufs.nfrac.aoflux
           COUPLER_CALENDAR: 2
                  WE2E_TEST: NO
            nnodes_forecast: 1
                 CCPP_SUITE: FV3_GFS_v17_p8_ugwpv1
                    MACHINE: singularity
               OBS_IMS_SNOW: YES
   ...
            NPROCS_ANALYSIS: 6
                      FHROT: 0
                      envir: test_lnd_era5_warm
      WRITE_TASKS_PER_GROUP: 6
                  OUTPUT_FH: 1 -1
                  COMINgdas: 
                  COLDSTART: NO
   INFO::/contrib/${USER}/landda/land-DA_workflow/sorc/conda/envs/land_da/lib/python3.12/site-packages/uwtools/config/validator.py::L76::0 schema-validation errors found in Rocoto config
   INFO::/contrib/${USER}/landda/land-DA_workflow/sorc/conda/envs/land_da/lib/python3.12/site-packages/uwtools/rocoto.py::L66::0 Rocoto XML validation errors found


.. _RunExptC:

Run the Experiment
********************

To run the experiment, users may submit tasks manually via ``rocotorun`` or use a script to automate submission.

.. _WflowOverviewC:

Workflow Overview
==================

.. include:: ../doc-snippets/wflow-task-table.rst

.. _automated-run-c:

Automated Run
==================

To submit jobs automatically, users should navigate to the experiment directory, download the ``run_expt.sh`` script, modify permissions, and run the script: 

.. code-block:: console

   cd /path/to/exp_case/<EXP_CASE_NAME>
   wget https://raw.githubusercontent.com/wiki/ufs-community/land-DA_workflow/run_expt.sh .
   chmod 755 run_expt.sh
   ./run_expt.sh

where ``<EXP_CASE_NAME>`` is replaced with the actual name of the experiment directory (e.g., ``lnd_era5_warmstart_00``).

To check the status of the experiment, see :numref:`Section %s <VerifySuccess>` on tracking experiment progress.

.. _manual-run-c:

Manual Submission
==================

Depending on the user's platform, it may be necessary to load Rocoto:

.. code-block::

   module load rocoto/1.3.7

.. include:: ../doc-snippets/manual-run.rst

See the :ref:`Workflow Overview <WflowOverviewC>` section to learn more about the steps in the workflow process.

.. _TrackProgressC:

Track Progress
================

.. include:: ../doc-snippets/track-progress.rst

.. _check-output-c:

Check Experiment Output
=========================

.. include:: ../doc-snippets/check-output.rst

.. _plotting-c:

Plotting Results
------------------

.. include:: ../doc-snippets/plotting.rst

Appendix
**********

.. _CloudHPC:

Working in the Cloud or on HPC Systems
=========================================

Users working on systems with limited disk space in their ``/home`` directory may need to set the ``SINGULARITY_CACHEDIR`` and ``SINGULARITY_TMPDIR`` environment variables to point to a location with adequate disk space. For example:

.. code-block:: 

   export SINGULARITY_CACHEDIR=/absolute/path/to/writable/directory/cache
   export SINGULARITY_TMPDIR=/absolute/path/to/writable/directory/tmp

where ``/absolute/path/to/writable/directory/`` refers to the absolute path to a writable directory with sufficient disk space. If the ``cache`` and ``tmp`` directories do not exist already, they must be created with a ``mkdir`` command. 

On NOAA Cloud systems, the ``sudo su``/``exit`` commands may also be required; users on other systems may be able to omit these. For example:
   
.. code-block:: 

   mkdir /lustre/cache
   mkdir /lustre/tmp
   sudo su
   export SINGULARITY_CACHEDIR=/lustre/cache
   export SINGULARITY_TMPDIR=/lustre/tmp
   exit

.. note:: 
   ``/lustre`` is a fast but non-persistent file system used on NOAA Cloud systems. To retain work completed in this directory, `tar the files <https://www.howtogeek.com/248780/how-to-compress-and-extract-files-using-the-tar-command-on-linux/>`_ and move them to the ``/contrib`` directory, which is much slower but persistent.

After setting the ``SINGULARITY_CACHEDIR`` and ``SINGULARITY_TMPDIR`` environment variables, users may continue to :ref:`build the container <BuildC>`.

