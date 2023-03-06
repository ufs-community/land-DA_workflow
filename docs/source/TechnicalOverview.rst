.. _TechOverview:

*********************
Technical Overview
*********************

Prerequisites
***************

Minimum System Requirements
==============================

:term:`UFS` applications, models, and components require a UNIX-based operating system (i.e., Linux or MacOS). 

Additionally, users will need:

   * Disk space: ~23GB (11GB for Land DA System [or 6.5GB for Land DA container], 11GB for Land DA data, and ~1GB for staging and output) 
   * 6 CPU cores (or option to run with "oversubscribe")

Software Prerequisites
========================

The Land DA System requires:

   * An :term:`MPI` implementation
   * Fortran compiler
   * Python
   * :term:`NetCDF`
   * Lmod 
   * `spack-stack <https://spack-stack.readthedocs.io/en/latest/>`__
   * `FV3-bundle <https://github.com/JCSDA/fv3-bundle/wiki>`__   

These software prerequisites are pre-installed in the Land DA :term:`container` and on other Level 1 systems (see :ref:`below <LevelsOfSupport>` for details). However, users on non-Level 1 systems will need to install them.

Before using the Land DA container, users will need to install `Singularity <https://docs.sylabs.io/guides/latest/user-guide/>`__ and an **Intel** MPI (available `free here <https://www.intel.com/content/www/us/en/developer/tools/oneapi/hpc-toolkit-download.html>`__). 


.. _LevelsOfSupport:

Supported Systems for Running Land DA
****************************************

Four levels of support have been defined for :term:`UFS` applications, and the Land DA system operates under this paradigm: 

* **Level 1** *(Pre-configured)*: Prerequisite software libraries are pre-built and available in a central location; code builds; full testing of model.
* **Level 2** *(Configurable)*: Prerequisite libraries are not available in a centralized location but are expected to install successfully; code builds; full testing of model.
* **Level 3** *(Limited-test platforms)*: Libraries and code build on these systems, but there is limited testing of the model.
* **Level 4** *(Build-only platforms)*: Libraries and code build, but running the model is not tested.

Level 1 Systems
==================
Preconfigured (Level 1) systems for Land DA already have the required external libraries available in a central location via :term:`spack-stack` and :term:`JEDI`'s fv3-bundle. Land DA is expected to build and run out-of-the-box on these systems, and users can download the Land DA code without first installing prerequisite software. With the exception of the Land DA container, users must have access to these Level 1 systems in order to use them.

+-----------+-----------------------------------+----------------------------------------------------------------------------+
| Platform  | Compiler/MPI                      | spack-stack & fv3-bundle Installations                                     |
+===========+===================================+============================================================================+
| Hera      | intel/2022.1.2 /                  | /scratch1/NCEPDEV/nems/role.epic/spack-stack/envs/landda-release-1.0-intel |
|           |                                   |                                                                            |
|           | impi/2022.1.2                     | /scratch1/NCEPDEV/nems/role.epic/contrib/fv3-bundle                        |
+-----------+-----------------------------------+----------------------------------------------------------------------------+
| Orion     | intel/2022.1.2 /                  | /work/noaa/epic-ps/role-epic-ps/spack-stack/envs/landda-release-1.0-intel  |
|           |                                   |                                                                            |
|           | impi/2022.1.2                     | /work/noaa/epic-ps/role-epic-ps/contrib/fv3-bundle                         |
+-----------+-----------------------------------+----------------------------------------------------------------------------+
| Container | intel-oneapi-compilers/2021.8.0 / | /opt/spack-stack/ (inside the container)                                   |
|           |                                   |                                                                            |
|           | intel-oneapi-mpi/2021.8.0         | /opt/fv3-bundle (inside the container)                                     |
+-----------+-----------------------------------+----------------------------------------------------------------------------+

Level 2-4 Systems
===================

On non-Level 1 platforms, the Land DA system can be run within a container that includes the prerequisite software; otherwise, the required libraries will need to be installed as part of the Land DA build process. Once these prerequisite libraries are installed, applications and models should build and run successfully. However, users may need to perform additional troubleshooting on Level 3 or 4 systems since little or no pre-release testing has been conducted on these systems.

.. note::

   Running on Jet, Cheyenne, and NOAA Cloud systems is supported via container. 

Code Repositories and Directory Structure
********************************************

Directory Structure
======================

The main repository for the Land DA System is named ``land-offline_workflow``; 
it is available on GitHub at https://github.com/NOAA-EPIC/land-offline_workflow/. 
A number of submodules are nested under the main ``land-offline_workflow`` directory. 
When the ``release/public-v1.0.0`` branch of the ``land-offline_workflow`` repository 
is cloned with the ``--recursive`` argument, the basic directory structure will be 
similar to the example below. Some files and directories have been removed for brevity. 

.. code-block:: console

   land-offline_workflow
    ├── DA_update
    │     ├── add_jedi_incr
    │     ├── jedi/fv3-jedi
    │     └── do_LandDA.sh
    ├── cmake
    ├── configures
    ├── docs
    ├── modulefiles
    ├── test
    ├── ufs-land-driver
    │     └── ccpp-physics
    ├── vector2tile
    ├── CMakeLists.txt
    ├── README.md
    ├── LICENSE
    ├── do_submit_cycle.sh
    ├── release.environment
    ├── settings_DA_*
    ├── submit_cycle.sh
    └── template.*

Land DA Components
=====================

:numref:`Table %s <LandDAComponents>` describes the various subrepositories that form
the UFS Land DA System. 

.. _LandDAComponents:

.. table:: UFS Land DA System Components

   +--------------------------+-----------------------------------------+------------------------------------------------------+
   | Repository Name          | Repository Description                  | Authoritative repository URL                         |
   +==========================+=========================================+======================================================+
   | land-DA_update           | Contains scripts and components for     | https://github.com/NOAA-EPIC/land-DA_update          |
   |                          | performing data assimilation (DA)       |                                                      |
   |                          | procedures.                             |                                                      |
   +--------------------------+-----------------------------------------+------------------------------------------------------+
   | *-- land-apply_jedi_incr*| Contains code that applies the          | https://github.com/NOAA-PSL/land-apply_jedi_incr     |
   |                          | JEDI-generated DA increment to UFS      |                                                      |
   |                          | ``sfc_data`` restart                    |                                                      |
   +--------------------------+-----------------------------------------+------------------------------------------------------+
   | ufs-land-driver          | Repository for the UFS Land             | https://github.com/NOAA-EMC/ufs-land-driver          | 
   |                          | Driver                                  |                                                      |
   +--------------------------+-----------------------------------------+------------------------------------------------------+
   | *-- ccpp-physics*        | Repository for the Common               | https://github.com/NCAR/ccpp-physics                 |
   |                          | Community Physics Package (CCPP)        |                                                      |
   |                          |                                         |                                                      |
   +--------------------------+-----------------------------------------+------------------------------------------------------+
   | land-vector2tile         | Contains code to map between the vector | https://github.com/NOAA-PSL/land-vector2tile         |
   |                          | format used by the Noah-MP offline      |                                                      |
   |                          | driver, and the tile format used by the |                                                      |
   |                          | UFS atmospheric model.                  |                                                      |
   +--------------------------+-----------------------------------------+------------------------------------------------------+

