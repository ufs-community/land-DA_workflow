.. _Container:

**********************************
Containerized Land DA Workflow
**********************************

These instructions will help users build and run a basic case for the Unified Forecast System (:term:`UFS`) Land Data Assimilation (DA) System using a `Singularity/Apptainer <https://apptainer.org/docs/user/latest/>`_ container. The Land DA :term:`container` packages together the Land DA System with its dependencies (e.g., :term:`spack-stack`, :term:`JEDI`) and provides a uniform environment in which to build and run the Land DA System. Normally, the details of building and running Earth system models will vary based on the computing platform because there are many possible combinations of operating systems, compilers, :term:`MPIs <MPI>`, and package versions available. Installation via Singularity/Apptainer container reduces this variability and allows for a smoother experience building and running Land DA. This approach is recommended for users not running Land DA on a supported :ref:`Level 1 <LevelsOfSupport>` system (e.g., Hera, Orion). 

This chapter provides instructions for building and running the Unified Forecast System (:term:`UFS`) Land DA System in a container using a Jan. 19-20, 2025 00z sample. This case is a :term:`LND` :term:`warmstart` configuration that uses :term:`ERA5` and :term:`IMS` data and the 3D-Var algorithm. 

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

   As of November 2021, the Linux-supported version of Singularity has been `renamed <https://apptainer.org/news/community-announcement-20211130/>`_ to *Apptainer*. Apptainer has maintained compatibility with Singularity, so ``singularity`` commands should work with either Singularity or Apptainer (see `compatibility details here <https://apptainer.org/docs/user/1.2/introduction.html>`_.)

.. attention:: 
   Docker containers can only be run with root privileges, and users generally do not have root privileges on :term:`HPCs <HPC>`. However, an Apptainer image may be built directly from a Docker image for use on the system.

.. _create-dir-c:

Create a Working Directory
*****************************

.. include:: ../doc-snippets/create-work-dir.rst

.. _GetDataC:

Get Data
***********

In order to run the Land DA System, users will need input data in the form of fix files, model forcing files, restart files, and observations for data assimilation. These files are already present on Level 1 systems (see :numref:`Section %s <Level1Data>` for details). 

Users on any system may download and untar the data from the `Land DA Data Bucket <https://registry.opendata.aws/noaa-ufs-land-da/>`_ into their ``$LANDDAROOT`` directory. In the working directory, run: 

.. code-block:: console

   cd $LANDDAROOT
   wget https://noaa-ufs-land-da-pds.s3.amazonaws.com/CADRE-2025/Land-DA_v2.1_inputs.tar.gz
   tar xvfz Land-DA_v2.1_inputs.tar.gz

.. _DownloadContainer:

Download or Build the Container
*********************************

Users can download the ``ubuntu22.04-intel-landda-release-public-v2.0.0.img`` container from the `Land DA Data Bucket <https://registry.opendata.aws/noaa-ufs-land-da/>`_ or build the Singularity container from a public Docker :term:`container` image. Downloading may be faster depending on the download speed on the user's system. 

Download the Container
========================

To download from the data bucket, users can run:

.. code-block:: console

   wget https://noaa-ufs-land-da-pds.s3.amazonaws.com/CADRE-2025/ubuntu22.04-intel-landda-daconsortium.img

This will download a container image named ``ubuntu22.04-intel-landda-daconsortium.img``. Users may continue to :ref:`set up the container <SetUpContainer>`.

.. _BuildC:

Build the Container
=====================

Alternatively, users can build the container from a Docker image. (Users who have already downloaded the container may skip to the :ref:`next section <SetUpContainer>`.) Users working on systems with limited disk space in their ``/home`` directory will need to set the ``SINGULARITY_CACHEDIR`` and ``SINGULARITY_TMPDIR`` environment variables to point to a location with adequate disk space. For example:

.. code-block:: 

   export SINGULARITY_CACHEDIR=/absolute/path/to/writable/directory/cache
   export SINGULARITY_TMPDIR=/absolute/path/to/writable/directory/tmp

See detailed instructions for this in :numref:`Section %s <CloudHPC>`. Then, run: 

.. code-block:: console

   singularity build --force ubuntu22.04-intel-landda-daconsortium.img docker://noaaepic/ubuntu22.04-intel21.10-landda:ue160-fms202401-daconsortium

This process may take several hours depending on the system. 

.. note:: 

   Some users may need to issue the ``singularity build`` command with ``sudo`` (i.e., ``sudo singularity build...``). Whether ``sudo`` is required is system-dependent. If ``sudo`` is required (or desired) for building the container, users should set the ``SINGULARITY_CACHEDIR`` and ``SINGULARITY_TMPDIR`` environment variables with ``sudo su``, as in the NOAA Cloud example from :numref:`Section %s <CloudHPC>` below.

.. _SetUpContainer:

Set Up the Container
*********************

Create experiment variables that point to the container image (``${img}``) and, if necessary, the location of the data (``${LANDDA_INPUTS}``). Users only need to set the location of the data if they added it in a location other than ``$LANDDAROOT``: 

.. code-block:: console

   # Set path to container
   export img=/path/to/ubuntu22.04-intel-landda-daconsortium.img

   # Set path to data (if necessary)
   export LANDDA_INPUTS=/path/to/inputs

where ``/path/to`` is replaced by the absolute path to the location of the container and Land DA input data. 

Within the ``$LANDDAROOT`` directory, copy the ``setup_container.sh`` script out of the container. 

.. code-block:: console

   singularity exec -H $PWD $img cp -r /opt/land-DA_workflow/setup_container.sh .

The ``setup_container.sh`` script should now be in the ``$LANDDAROOT`` directory. Note that if previous steps included a ``sudo`` command, ``sudo`` may be required in front of this command for it to work. If for some reason, the previous command was unsuccessful, users may try a version of the following command instead: 

.. code-block:: console

   singularity exec -B /<local_base_dir>:/<container_dir> $img cp -r /opt/land-DA_workflow/setup_container.sh .

where ``<local_base_dir>`` and ``<container_dir>`` are replaced with a top-level directory on the local system and in the container, respectively. Additional directories can be bound by adding another ``-B /<local_base_dir>:/<container_dir>`` argument before the container location (``$img``). 

.. note::

   Users may convert a container ``.img`` file to a writable sandbox. This step is optional on most systems but allows users to make changes to the container if desired:

   .. code-block:: console

      singularity build --sandbox ubuntu22.04-intel-landda-daconsortium $img

   Sometimes binding directories with different names can cause problems. In general, it is recommended that the local base directory and the container directory have the same name. For example, if the host system's top-level directory is ``/user1234``, the user may want to convert the ``.img`` file to a writable sandbox and create a ``user1234`` directory in the sandbox to bind to. 

Run the ``setup_container.sh`` script with the proper arguments.

.. code-block:: console

   ./setup_container.sh -c=<compiler> -m=<mpi_implementation> -i=$img

where:

   * ``-c`` is the compiler on the user's local machine ( e.g., ``intel/2022.1.2``, ``intelmpi/2021.13``)
   * ``-m`` is the :term:`MPI` on the user's local machine ( e.g., ``intel/2022.1.2``, ``intelmpi/2021.13``)
   * ``-i`` is the full path to the container image ( e.g., ``$LANDDAROOT/ubuntu22.04-intel-landda-daconsortium.img``).

Concretely, users would run something like: 

.. code-block:: console
   
   ./setup_container.sh -c=intel/2022.1.2 -m=intel/2022.1.2 -i=$img

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

The user should now see the ``land-DA_workflow`` and ``jedi-bundle`` directories in the ``$LANDDAROOT`` directory. 

Containers come with pre-built executables, so users may continue to the next section to configure the experiment. However, users who are interested in learning how to build the executables can skip to :numref:`Section %s <build-exe>` to learn how to build their own executables to use in their experiment. 

.. _ConfigureExptC:

Configure the Experiment
===========================

To configure an experiment, first load the workflow modulefiles for the container: 

.. code-block:: console

   cd land-DA_workflow
   module use modulefiles
   module load wflow_singularity

Then navigate to the ``parm`` directory and copy the desired case (e.g., ``config.LND.era5.3dvar.ims.warmstart.yaml``) into ``config.yaml``: 

.. code-block:: console

   cd parm
   cp config_samples/config.<case>.yaml config.yaml

where ``<case>`` is the name of one of the sample case files in the `samples_cadre <https://github.com/ufs-community/land-DA_workflow/tree/develop/parm/config_samples>`_ directory. 

For example, when running the ``LND.era5.3dvar.ims.warmstart`` case, run:

.. code-block:: console

   cd parm
   cp config_samples/config.LND.era5.3dvar.ims.warmstart.yaml config.yaml

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


ATML Configurations Only
==========================

For :term:`ATML` configurations only (e.g., ``cadre3``), users must modify the ``run_container_executable.sh`` script using a code editor of their choice. For example: 

.. code-block:: console

   vim run_container_executable.sh

Uncomment the second-to-last line of the script, which adds the executables to the container by exporting the ``SINGULARITYENV_PREPEND_PATH`` variable:

.. code-block:: console

   # Uncomment the line below when running the ATML experiment
   export SINGULARITYENV_PREPEND_PATH=/home/ubuntu/land-DA_workflow/sorc/build/bin:$SINGULARITYENV_PREPEND_PATH
   ${SINGULARITYBIN} exec -B $BINDDIR:$BINDDIR -B $CONTAINERBASE:$CONTAINERBASE $INPUTBIND $img $cmd $arg

.. hint:: 

   When using ``vim``, hit the ``i`` key to enter insert mode and make any changes required. To close and save, hit the ``esc`` key and type ``:wq`` to write the changes to the file and exit/quit the file. Users may opt to use their preferred code editor instead. 


.. _RunExptC:

Run the Experiment
********************

To run the experiment, users must submit tasks manually via ``rocotorun``. :term:`cron` automation is not yet supported for containers. 

.. _WflowOverviewC:

Workflow Overview
==================

.. include:: ../doc-snippets/wflow-task-table.rst

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

where ``/absolute/path/to/writable/directory/`` refers to the absolute path to a writable directory with sufficient disk space. If the ``cache`` and ``tmp`` directories do not exist already, they must be created with a ``mkdir`` command. If the ``cache`` and ``tmp`` directories do not exist already, they must be created with a ``mkdir`` command. 

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

.. _build-exe:

Building the Executables
==========================

The executables come pre-built in the Land DA Container. However, users who are curious about building the executables using the ``app_build.sh`` script can follow the instructions here. 

#. Shell into the container.
   
   .. code-block:: console 
      
      singularity shell -B /home:/home /home/ubuntu/ubuntu22.04-intel-landda-daconsortium.img

#. Go to the ``land-DA_workflow`` directory in the container.

   .. code-block:: console

      cd /home/ubuntu/land-DA_workflow/sorc

#. Set up the environment by sourcing the container's spack-stack installation and loading the container modulefiles. 

   .. code-block:: console
      
      source /opt/spack-stack/spack-stack-1.6.0/envs/fms-2024.01/.bashenv-fms
      module use ../modulefiles
      module load build_singularity_intel

#. Build the model using ``app_build.sh``. Users must select either the :term:`ATML` configuration (``-a=ATML``) or the :term:`LND` configuration when building. Users indicate that the platform (``-p``) is a container using the ``-p=singularity`` argument. Conda was pre-built in previous steps, so users should include the ``--conda=off`` argument to avoid rebuilding it. The ``--build`` option keeps the executables in the ``build`` directory under ``bin``. 

   .. code-block:: console

      # Build ATML configuration (Noah-MP + FV3)
      ./app_build.sh -p=singularity -a=ATML --conda=off --build

      # Build LND configuration (Noah-MP + DATM)
      ./app_build.sh -p=singularity --conda=off --build


.. note:: 
   
   The ``parm/run_container_executable.sh`` script looks for the executables built by the ``app_build.sh`` script. If users decide not to use this script to build the ATML exectuables, then the ``run_container_executable.sh`` script will need to point to the location of the prebuilt executables: 

   * Pre-built LND executable: ``/opt/land-DA_workflow/install/bin``
   * Pre-built ATML executable: ``/opt/land-DA_workflow/sorc/build-atml/bin/``. 

After building the executables, continue to :numref:`Section %s: Configure the Experiment <ConfigureExptC>`.
