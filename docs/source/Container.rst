.. _Container:

**********************************
Running Land DA in a Container
**********************************

.. attention::

      The user must have an Intel compiler and MPI on their system because the container uses an Intel compiler and MPI. Intel compilers are now available for free as part of `Intel's oneAPI Toolkit <https://www.intel.com/content/www/us/en/developer/tools/oneapi/hpc-toolkit-download.html>`__.

These instructions will help users build and run a basic case for the Unified Forecast System (:term:`UFS`) Land Data Assimilation System (Land DA) using a `Singularity <https://sylabs.io/guides/3.5/user-guide/introduction.html>`__ container. The :term:`container` approach provides a uniform environment in which to build and run Land DA. Normally, the details of building and running Earth systems models will vary based on the computing platform because there are many possible combinations of operating systems, compilers, :term:`MPIs <MPI>`, and package versions available. Installation via Singularity container reduces this variability and allows for a smoother experience building and running Land DA. 

The "out-of-the-box" Land DA case described in this User's Guide builds a weather forecast for January 1-2, 2016. 

.. COMMENT: Check date

.. attention::

   * Land DA has :ref:`four levels of support <LevelsOfSupport>`. The steps described in this chapter will work most smoothly on preconfigured (Level 1) systems or on other NOAA RDHPCS systems. However, this guide can serve as a starting point for running Land DA on other systems, too. 
   * This chapter of the User's Guide should **only** be used for container builds. For non-container builds, see :numref:`Chapter %s <BuildRunLandDA>` for a Quick Start Guide to building Land DA **without** a container. 

.. _Prereqs:

Prerequisites 
*****************

The containerized version of Land DA requires: 

   * Installation of Singularity 
   * At least 6 CPU cores
   * An **Intel** compiler and :term:`MPI` (available for free `here <https://www.intel.com/content/www/us/en/developer/tools/oneapi/hpc-toolkit-download.html>`__) 


Install Singularity
======================

To build and run Land DA using a Singularity container, first install the Singularity package according to the `Singularity Installation Guide <https://docs.sylabs.io/guides/3.2/user-guide/installation.html>`__. This will include the installation of dependencies and the installation of the Go programming language. SingularityCE Version 3.7 or above is recommended. 

.. warning:: 
   Docker containers can only be run with root privileges, and users generally do not have root privileges on :term:`HPCs <HPC>`. However, a Singularity image may be built directly from a Docker image for use on the system.

.. _DownloadContainer:

Download the Container
*************************

.. _CloudHPC:

Set Environment Variables
=============================

For users working on systems with limited disk space in their ``/home`` directory, it is important to set the ``SINGULARITY_CACHEDIR`` and ``SINGULARITY_TMPDIR`` environment variables to point to a location with adequate disk space. (Other users may not need to do this.) For example:

.. code-block:: 

   export SINGULARITY_CACHEDIR=/absolute/path/to/writable/directory/cache
   export SINGULARITY_TMPDIR=/absolute/path/to/writable/directory/tmp

where ``/absolute/path/to/writable/directory/`` refers to a writable directory (usually a project or user directory within ``/lustre``, ``/work``, ``/scratch``, or ``/glade`` on NOAA Level 1 systems). If the ``cache`` and ``tmp`` directories do not exist already, they must be created with a ``mkdir`` command. 

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

.. hint::
   If a ``singularity: command not found`` error message appears in any of the following steps, try running: ``module load singularity``.

Set a top-level directory location for Land DA work, and navigate to it. For example:

.. code-block:: console 

   export LANDDAROOT=/path/to/landda
   [[ -d $LANDDAROOT ]] || mkdir -p $LANDDAROOT 
   cd $LANDDAROOT

where ``/path/to/landda`` is the path to this top-level directory (e.g., ``/Users/Joe.Schmoe/landda``). The second line will create the directory if it does not exist yet. 

NOAA RDHPCS Systems
----------------------

On many NOAA RDHPCS systems, a container named ``ubuntu20.04-intel-spack-landda.img`` has already been built:

.. table:: Locations of pre-built containers

   +--------------+--------------------------------------------------------+
   | Machine      | File location                                          |
   +==============+========================================================+
   | Cheyenne     | /glade/scratch/epicufsrt/containers                    |
   +--------------+--------------------------------------------------------+
   | Hera         | /scratch1/NCEPDEV/nems/role.epic/containers            |
   +--------------+--------------------------------------------------------+
   | Jet          | /mnt/lfs4/HFIP/hfv3gfs/role.epic/containers            |
   +--------------+--------------------------------------------------------+
   | Orion        | /work/noaa/epic-ps/role-epic-ps/containers             |
   +--------------+--------------------------------------------------------+

.. note::
   Singularity is not available on Gaea, and therefore, container use is not supported on Gaea. 


.. COMMENT: Omit? 
   Users can simply copy the container to their local working directory. For example, on Jet:

   .. code-block:: console

      cp /mnt/lfs4/HFIP/hfv3gfs/role.epic/containers/ubuntu20.04-intel-spack-landda.img .

   Users can also build the container from scratch using the following commands:

   .. code-block::

      singularity build ubuntu20.04-intel-spack-landda.img docker://noaaepic/ubuntu20.04-intel-landda:release-public-v1.0.0

.. COMMENT: Do we still need?

   .. note::

      Building the container from scratch can take a while and will likely require making the changes mentioned in :numref:`Section %s <CloudHPC>` above. 

   Users may convert a container ``.img`` file to a writable sandbox. This step is required when running on Cheyenne but is optional on other systems:

   .. COMMENT: Check whether this is still true^

   .. code-block:: console

      singularity build --sandbox ubuntu20.04-intel-spack-landda ubuntu20.04-intel-spack-landda.img

   When making a writable sandbox on Level 1 systems, the following warnings commonly appear and can be ignored:

   .. code-block:: console

      INFO:    Starting build...
      INFO:    Verifying bootstrap image ubuntu20.04-intel-spack-landda.img
      WARNING: integrity: signature not found for object group 1
      WARNING: Bootstrap image could not be verified, but build will continue.

Non-NOAA RDHPCS Systems
--------------------------

On other systems, users can build the singularity container from a public :term:`Docker` container image. 

.. code-block:: console

   singularity build ubuntu20.04-intel-landda.img docker://noaaepic/ubuntu20.04-intel-landda:release-public-v1.0.0

This process may take several hours. 

Some users may need to issue the ``singularity build`` command with ``sudo`` (i.e., ``sudo singularity build...``). Whether ``sudo`` is required is system-dependent. 

.. COMMENT: 
   On other systems, users should build the container in a writable sandbox:

   .. code-block:: console

      sudo singularity build --sandbox ubuntu20.04-intel-spack-landda docker://noaaepic/ubuntu20.04-intel-landda:release-public-v1.0.0


.. _GetData:

Get Data
***********

In order to run the Land DA system, users will need input data in the form of fix files, model forcing files, restart files, and observations for data assimilation. These files are already present on NOAA RDHPCS systems, and users may copy or link them. The files reside in the ``$EPICHOME/landda/inputs`` directory, to their ``$LANDDAROOT`` directory. 

.. code-block::console

   cp $EPICHOME/landda/inputs $LANDDAROOT
   # OR
   ln -s $EPICHOME/landda/inputs $LANDDAROOT

.. COMMENT: Verify add/export the $EPICHOME dir paths on all systems
   Per Mark: (this might have “contrib” in the path on some machines. we should make sure it is the same everywhere).

Users on any system may download and untar the data from the `Land DA Data Bucket <https://noaa-ufs-land-da-pds.s3.amazonaws.com>`__ into their ``$LANDDAROOT`` directory. 

.. code-block:: console

   wget https://noaa-ufs-land-da-pds.s3.amazonaws.com/current_land_da_release_data/landda-input-data-{YEAR}.tar.gz
   tar xvfz landda-input-data-{YEAR}.tar.gz

replacing ``{YEAR}`` with either ``2016`` or ``2020``. The default name for the untarred file is ``inputs``. 

.. COMMENT: Delete?

   Define a ``$LANDDADATA`` directory where data files for Land DA experiments will be located. The data already exists on Tier 1 NOAA RDHPCS systems, and there is no need to download it. 

   .. code-block:: console

      export LANDDADATA=/path/to/landda/data
      [[ -d $LANDDADATA ]] || mkdir -p $LANDDADATA 
      cd $LANDDADATA

   where ``/path/to/landda/data`` is the directory where Land DA-related datasets will reside (e.g., ``/Users/janedoe/landda/data``). 




.. COMMENT: Will some of this become relevant?
   Download and Stage the Data
   ============================

   On Level 1 systems, the data required to run SRW App tests are already available as long as the bind argument (starting with ``-B``) in :numref:`Step %s <BuildC>` included the directory with the input model data. See :numref:`Table %s <DataLocations>` for Level 1 data locations. For Level 2-4 systems, the data must be added manually by the user. 



.. _RunContainer:

Run the Container
********************

To run the container, users must:

   #. :ref:`Set up the container <SetUpContainer>`
   #. :ref:`Allocate a compute node <AllocateComputeNode>`
   #. :ref:`Submit the experiment <SubmitExpt>`

.. COMMENT: Update!

.. _SetUpContainer:

Set Up the Container
=======================

Save the location of the container in an environment variable.

.. code-block:: console

   export img=path/to/ubuntu20.04-intel-landda.img

.. COMMENT: Check name of container!

Set the ``USE_SINGULARITY`` environment variable to "yes". 

.. code-block:: console

   export USE_SINGULARITY=yes

This variable tells the workflow to use the containerized version of all the executables (including python) when running a cycle. 

From within the ``$LANDDAROOT`` directory, copy the ``land-offline_workflow`` directory out of the container so that it sits next to the new ``inputs`` directory/link. 

.. code-block:: console

   singularity exec -H $PWD $img cp -r /opt/land-offline_workflow .

There should now be an ``inputs`` directory (for the data) and a ``land-offline_workflow`` directory (for the workflow) in the ``$LANDDAROOT`` directory. Navigate into the ``land-offline_workflow`` directory.

.. code-block:: console

   cd land-offline_workflow

.. COMMENT: 
   Initialize Lmod module management needs to be available; initialize Lmod environment if not done by default:

      .. code-block:: console

      BASH_ENV=/apps/lmod/lmod/init/bash
      source $BASH_ENV

When using a Singularity container, Intel compilers and Intel MPI (``mpiexec`` command) need to be available on the host system to properly launch MPI jobs (preferrably 2020 versions or newer). Generally, this is accomplished by loading a module with a recent Intel compiler and then loading the corresponding ``intelmpi``. For example, users can modify the following commands to load their system's compiler/MPI combination:

.. code-block:: console

   module load intel/2022.1.2 impi/2022.1.2


Configure the Experiment
===========================

Users on a system with a slurm job scheduler will need to make some minor changes to the ``submit_cycle.sh`` file. Open the file and change the account and queues (qos) to match the desired account and qos on the system. Users may also need to add the following line to the script to specify the partition: 

.. code-block:: console

   #SBATCH –partition=my_partition
   
Save and close the file.

.. _RunExptC:

Run the Experiment
=====================

The Land DA system uses a script-based workflow that is launched using the ``do_submit_cycle.sh`` script. That script requires an input file that details all the specifics of a given experiment. EPIC has provided four sample ``settings_*`` files as examples: ``settings_DA_cycle_gdas``, ``settings_DA_cycle_era5``, ``settings_DA_cycle_gdas_restart``, and ``settings_DA_cycle_era5_restart``. The ``*restart`` settings files will only work after an experiment with the corresponding non-restart settings file has been run. This is because they are designed to use the restart files created by the first experiment cycle to pick up where it left off. (e.g., ``settings_DA_cycle_gdas`` runs from 01/01/2016 18z to 01/03/2016 18z. The ``settings_DA_cycle_gdas_restart`` will run from 01/03/2016 18z to 01/04/2016 18z.)

To start an experiment, run either: 

.. code-block:: console
   
   ./do_submit_cycle.sh settings_DA_cycle_gdas
   #OR 
   ./do_submit_cycle.sh settings_DA_cycle_era5

.. COMMENT: Indicate which to use when!

The ``do_submit_cycle.sh`` script will read the ``settings_DA_cycle_*`` file as well as the ``release.environment`` file, which contains sensible experiment default values to simplify the process of running the workflow for the first time. Advanced users will wish to modify many of these parameters to fit their particular needs. After reading the defaults and other variables from the settings files, ``do_submit_cycle.sh`` creates a work directory and an output directory called ``landda_expts`` in the parent directory of ``land-offline_workflow`` and then submits a job (``submit_cycle.sh``) to the queue that will run through the workflow. If all succeeds, users will see ``log`` and ``err`` files created in ``land-offline_workflow`` along with a ``cycle.log`` file, which will show where the cycle has ended. The ``landda_expts`` directory will also be populated with data in the following directories:

.. code-block:: console

   landda_expts/DA_GHCN_test/DA/
   landda_expts/DA_GHCN_test/mem000/restarts/vector/

