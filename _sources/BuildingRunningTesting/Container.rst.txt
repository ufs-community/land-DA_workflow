.. _Container:

**********************************
Containerized Land DA Workflow
**********************************

These instructions will help users build and run a basic case for the Unified Forecast System (:term:`UFS`) Land Data Assimilation (DA) System using a `Singularity/Apptainer <https://apptainer.org/docs/user/main/>`__ container. The Land DA :term:`container` packages together the Land DA System with its dependencies (e.g., :term:`spack-stack`, :term:`JEDI`) and provides a uniform environment in which to build and run the Land DA System. Normally, the details of building and running Earth systems models will vary based on the computing platform because there are many possible combinations of operating systems, compilers, :term:`MPIs <MPI>`, and package versions available. Installation via Singularity/Apptainer container reduces this variability and allows for a smoother experience building and running Land DA. This approach is recommended for users not running Land DA on a supported :ref:`Level 1 <LevelsOfSupport>` system (i.e., Hera, Orion). 

This chapter provides instructions for building and running basic Land DA cases for the Unified Forecast System (:term:`UFS`) Land DA System. Users can choose between two options: 

   * A Dec. 21, 2019 00z sample case using :term:`ERA5` data with the UFS Land Driver (``settings_DA_cycle_era5``)
   * A Jan. 3, 2000 00z sample case using :term:`GSWP3` data with the UFS Noah-MP land component (``settings_DA_cycle_gswp3``). 

.. attention::

   This chapter of the User's Guide should **only** be used for container builds. For non-container builds, see :numref:`Chapter %s <BuildRunLandDA>`, which describes the steps for building and running Land DA on a :ref:`Level 1 System <LevelsOfSupport>` **without** a container. 

.. _Prereqs:

Prerequisites 
*****************

The containerized version of Land DA requires: 

   * `Installation of Apptainer <https://apptainer.org/docs/admin/1.2/installation.html>`__
   * At least 6 CPU cores
   * An **Intel** compiler and :term:`MPI` (available for free `here <https://www.intel.com/content/www/us/en/developer/tools/oneapi/hpc-toolkit-download.html>`__) 


Install Singularity/Apptainer
===============================

.. note::

   As of November 2021, the Linux-supported version of Singularity has been `renamed <https://apptainer.org/news/community-announcement-20211130/>`__ to *Apptainer*. Apptainer has maintained compatibility with Singularity, so ``singularity`` commands should work with either Singularity or Apptainer (see compatibility details `here <https://apptainer.org/docs/user/1.2/introduction.html>`__.)

To build and run Land DA using a Singularity/Apptainer container, first install the software according to the `Apptainer Installation Guide <https://apptainer.org/docs/admin/1.2/installation.html>`__. This will include the installation of all dependencies. 

.. attention:: 
   Docker containers can only be run with root privileges, and users generally do not have root privileges on :term:`HPCs <HPC>`. However, a Singularity image may be built directly from a Docker image for use on the system.

.. _DownloadContainer:

Build the Container
**********************

.. _CloudHPC:

Set Environment Variables
=============================

For users working on systems with limited disk space in their ``/home`` directory, it is important to set the ``SINGULARITY_CACHEDIR`` and ``SINGULARITY_TMPDIR`` environment variables to point to a location with adequate disk space. For example:

.. code-block:: 

   export SINGULARITY_CACHEDIR=/absolute/path/to/writable/directory/cache
   export SINGULARITY_TMPDIR=/absolute/path/to/writable/directory/tmp

where ``/absolute/path/to/writable/directory/`` refers to a writable directory (usually a project or user directory within ``/lustre``, ``/work``, ``/scratch``, or ``/glade`` on NOAA :term:`RDHPCS` systems). If the ``cache`` and ``tmp`` directories do not exist already, they must be created with a ``mkdir`` command. 

On NOAA Cloud systems, the ``sudo su`` command may also be required:
   
.. code-block:: 

   mkdir /lustre/cache
   mkdir /lustre/tmp
   sudo su
   export SINGULARITY_CACHEDIR=/lustre/cache
   export SINGULARITY_TMPDIR=/lustre/tmp
   exit

.. note:: 
   ``/lustre`` is a fast but non-persistent file system used on NOAA Cloud systems. To retain work completed in this directory, `tar the files <https://www.howtogeek.com/248780/how-to-compress-and-extract-files-using-the-tar-command-on-linux/>`__ and move them to the ``/contrib`` directory, which is much slower but persistent.

.. _ContainerBuild:

Build the Container
======================

Set a top-level directory location for Land DA work, and navigate to it. For example:

.. code-block:: console 

   mkdir /path/to/landda
   cd /path/to/landda
   export LANDDAROOT=`pwd`

where ``/path/to/landda`` is the path to this top-level directory (e.g., ``/Users/Joe.Schmoe/landda``). 

.. hint::
   If a ``singularity: command not found`` error message appears in any of the following steps, try running: ``module load singularity`` or (on Derecho) ``module load apptainer``.

NOAA RDHPCS Systems
----------------------

On many NOAA :term:`RDHPCS` systems, a container named ``ubuntu20.04-intel-landda-release-public-v1.2.0.img`` has already been built, and users may access the container at the locations in :numref:`Table %s <PreBuiltContainers>`.

.. _PreBuiltContainers:

.. table:: Locations of Pre-Built Containers

   +--------------+--------------------------------------------------------+
   | Machine      | File location                                          |
   +==============+========================================================+
   | Derecho      | /glade/work/epicufsrt/contrib/containers               |
   +--------------+--------------------------------------------------------+
   | Gaea         | /lustre/f2/dev/role.epic/contrib/containers            |
   +--------------+--------------------------------------------------------+
   | Hera         | /scratch1/NCEPDEV/nems/role.epic/containers            |
   +--------------+--------------------------------------------------------+
   | Jet          | /mnt/lfs4/HFIP/hfv3gfs/role.epic/containers            |
   +--------------+--------------------------------------------------------+
   | Orion        | /work/noaa/epic/role-epic/contrib/containers           |
   +--------------+--------------------------------------------------------+

Users can simply set an environment variable to point to the container: 

.. code-block:: console

   export img=path/to/ubuntu20.04-intel-landda-release-public-v1.2.0.img

If users prefer, they may copy the container to their local working directory. For example, on Jet:

.. code-block:: console

   cp /mnt/lfs4/HFIP/hfv3gfs/role.epic/containers/ubuntu20.04-intel-landda-release-public-v1.2.0.img .

Other Systems
----------------

On other systems, users can build the Singularity container from a public Docker :term:`container` image or download the ``ubuntu20.04-intel-landda-release-public-v1.2.0.img`` container from the `Land DA Data Bucket <https://registry.opendata.aws/noaa-ufs-land-da/>`__. Downloading may be faster depending on the download speed on the user's system. However, the container in the data bucket is the ``release/v1.2.0`` container rather than the updated ``develop`` branch container. 

To download from the data bucket, users can run:

.. code-block:: console

   wget https://noaa-ufs-land-da-pds.s3.amazonaws.com/current_land_da_release_data/v1.2.0/ubuntu20.04-intel-landda-release-public-v1.2.0.img

To build the container from a Docker image, users can run:

.. code-block:: console

   singularity build --force ubuntu20.04-intel-landda-release-public-v1.2.0.img docker://noaaepic/ubuntu20.04-intel-landda:release-public-v1.2.0

This process may take several hours depending on the system. 

.. note:: 

   Some users may need to issue the ``singularity build`` command with ``sudo`` (i.e., ``sudo singularity build...``). Whether ``sudo`` is required is system-dependent. If ``sudo`` is required (or desired) for building the container, users should set the ``SINGULARITY_CACHEDIR`` and ``SINGULARITY_TMPDIR`` environment variables with ``sudo su``, as in the NOAA Cloud example from :numref:`Section %s <CloudHPC>` above.

.. _GetDataC:

Get Data
***********

In order to run the Land DA System, users will need input data in the form of fix files, model forcing files, restart files, and observations for data assimilation. These files are already present on Level 1 systems (see :numref:`Section %s <Level1Data>` for details). 

Users on any system may download and untar the data from the `Land DA Data Bucket <https://registry.opendata.aws/noaa-ufs-land-da/>`__ into their ``$LANDDAROOT`` directory. 

.. code-block:: console

   cd $LANDDAROOT
   wget https://noaa-ufs-land-da-pds.s3.amazonaws.com/current_land_da_release_data/v1.2.0/Landdav1.2.0_input_data.tar.gz
   tar xvfz Landdav1.2.0_input_data.tar.gz

If users choose to add data in a location other than ``$LANDDAROOT``, they can set the input data directory by running:

.. code-block:: console

   export LANDDA_INPUTS=/path/to/input/data

where ``/path/to/input/data`` is replaced by the absolute path to the location of their Land DA input data. 

.. _RunContainer:

Run the Container
********************

To run the container, users must:

   #. :ref:`Set up the container <SetUpContainerC>`
   #. :ref:`Configure the experiment <ConfigureExptC>`
   #. :ref:`Run the experiment <RunExptC>`

.. _SetUpContainerC:

Set Up the Container
=======================

Save the location of the container in an environment variable.

.. code-block:: console

   export img=path/to/ubuntu20.04-intel-landda-release-public-v1.2.0.img

Set the ``USE_SINGULARITY`` environment variable to "yes". 

.. code-block:: console

   export USE_SINGULARITY=yes

This variable tells the workflow to use the containerized version of all the executables (including python) when running a cycle. 

Users may convert a container ``.img`` file to a writable sandbox. This step is optional on most systems:

.. code-block:: console

   singularity build --sandbox ubuntu20.04-intel-landda-release-public-v1.2.0 $img

When making a writable sandbox on NOAA RDHPCS systems, the following warnings commonly appear and can be ignored:

.. code-block:: console

   INFO:    Starting build...
   INFO:    Verifying bootstrap image ubuntu20.04-intel-landda-release-public-v1.2.0.img
   WARNING: integrity: signature not found for object group 1
   WARNING: Bootstrap image could not be verified, but build will continue.

From within the ``$LANDDAROOT`` directory, copy the ``land-DA_workflow`` directory out of the container. 

.. code-block:: console

   singularity exec -H $PWD $img cp -r /opt/land-DA_workflow .

There should now be a ``land-DA_workflow`` directory in the ``$LANDDAROOT`` directory. Navigate into the ``land-DA_workflow`` directory. If for some reason, this is unsuccessful, users may try a version of the following command instead: 

.. code-block:: console

   singularity exec -B /<local_base_dir>:/<container_dir> $img cp -r /opt/land-DA_workflow .

where ``<local_base_dir>`` and ``<container_dir>`` are replaced with a top-level directory on the local system and in the container, respectively. Additional directories can be bound by adding another ``-B /<local_base_dir>:/<container_dir>`` argument before the container location (``$img``). 

.. attention::
   
   Be sure to bind the directory that contains the experiment data! 

.. note::

   Sometimes binding directories with different names can cause problems. In general, it is recommended that the local base directory and the container directory have the same name. For example, if the host system's top-level directory is ``/user1234``, the user may want to convert the ``.img`` file to a writable sandbox and create a ``user1234`` directory in the sandbox to bind to. 

Navigate to the ``land-DA_workflow`` directory after it has been successfully copied into ``$LANDDAROOT``.

.. code-block:: console

   cd land-DA_workflow

When using a Singularity container, Intel compilers and Intel :term:`MPI` (preferably 2020 versions or newer) need to be available on the host system to properly launch MPI jobs. Generally, this is accomplished by loading a module with a recent Intel compiler and then loading the corresponding Intel MPI. For example, users can modify the following commands to load their system's compiler/MPI combination:

.. code-block:: console

   module load intel/2022.1.2 impi/2022.1.2

.. note:: 

   :term:`Spack-stack` uses lua modules, which require Lmod to be initialized for the ``module load`` command to work. If for some reason, Lmod is not initialized, users can source the ``init/bash`` file on their system before running the command above. For example, users can modify and run the following command: 

   .. code-block:: console

      source /path/to/init/bash
   
   Then they should be able to load the appropriate modules.

.. _ConfigureExptC:

Configure the Experiment
===========================

Modify Machine Settings
------------------------

Users on a system with a Slurm job scheduler will need to make some minor changes to the ``submit_cycle.sh`` file. Open the file and change the account and queue (qos) to match the desired account and qos on the system. Users may also need to add the following line to the script to specify the partition. For example, on Jet, users should set: 

.. code-block:: console

   #SBATCH --partition=xjet
   
When using the GSWP3 forcing option, users will need to update line 7 to say ``#SBATCH --cpus-per-task=4``. Users can perform this change manually in a code editor or run:

.. code-block:: console

   sed -i 's/--cpus-per-task=1/--cpus-per-task=4/g' submit_cycle.sh

Save and close the file.

Modify Experiment Settings
---------------------------

The Land DA System uses a script-based workflow that is launched using the ``do_submit_cycle.sh`` script. That script requires an input file that details all the specifics of a given experiment. EPIC has provided two sample ``settings_*`` files as examples: ``settings_DA_cycle_era5`` and ``settings_DA_cycle_gswp3``. 

.. attention::
   
   Note that the GSWP3 option will only run as-is on Hera and Orion. Users on other systems may need to make significant changes to configuration files, which is not a supported option for the |latestr| release. It is recommended that users on these systems use the UFS land driver ERA5 sample experiment set in ``settings_DA_cycle_era5``.

First, update the ``$BASELINE`` environment variable in the selected ``settings_DA_*`` file to say ``singularity.internal`` instead of ``hera.internal``:

.. code-block:: console

   export BASELINE=singularity.internal

When using the GSWP3 forcing option, users must also update the ``MACHINE_ID`` to ``orion`` in ``settings_DA_cycle_gswp3`` if running on Orion. 

.. _RunExptC:

Run the Experiment
=====================

To start the experiment, run: 

.. code-block:: console
   
   ./do_submit_cycle.sh settings_DA_cycle_era5

The ``do_submit_cycle.sh`` script will read the ``settings_DA_cycle_*`` file and the ``release.environment`` file, which contain sensible experiment default values to simplify the process of running the workflow for the first time. Advanced users will wish to modify the parameters in ``do_submit_cycle.sh`` to fit their particular needs. After reading the defaults and other variables from the settings files, ``do_submit_cycle.sh`` creates a working directory (named ``workdir`` by default) and an output directory called ``landda_expts`` in the parent directory of ``land-DA_workflow`` and then submits a job (``submit_cycle.sh``) to the queue that will run through the workflow. If all succeeds, users will see ``log`` and ``err`` files created in ``land-DA_workflow`` along with a ``cycle.log`` file, which will show where the cycle has ended. The ``landda_expts`` directory will also be populated with data in the following directories:

.. code-block:: console

   landda_expts/DA_GHCN_test/DA/
   landda_expts/DA_GHCN_test/mem000/restarts/vector/
   landda_expts/DA_GHCN_test/mem000/restarts/tile/

Depending on the experiment, either the ``vector`` or the ``tile`` directory will have data, but not both. 

Users can check experiment progress/success according to the instructions in :numref:`Section %s <VerifySuccess>`, which apply to both containerized and non-containerized versions of the Land DA System. 