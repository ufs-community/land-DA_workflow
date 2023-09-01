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
   * A Fortran compiler
   * Python
   * :term:`NetCDF`
   * Lmod 
   * `spack-stack <https://spack-stack.readthedocs.io/en/latest/>`__
   * `jedi-bundle <https://github.com/JCSDA/jedi-bundle/wiki>`__ (Skylab v3.0.)

These software prerequisites are pre-installed in the Land DA :term:`container` and on other Level 1 systems (see :ref:`below <LevelsOfSupport>` for details). However, users on non-Level 1 systems will need to install them.

Before using the Land DA container, users will need to install `Singularity <https://docs.sylabs.io/guides/latest/user-guide/>`__ and an **Intel** MPI (available `free here <https://www.intel.com/content/www/us/en/developer/tools/oneapi/hpc-toolkit-download.html>`__). 


.. _LevelsOfSupport:

Supported Systems for Running Land DA
****************************************

Four levels of support have been defined for :term:`UFS` applications, and the Land DA System operates under this paradigm: 

* **Level 1** *(Pre-configured)*: Prerequisite software libraries are pre-built and available in a central location; code builds; full testing of model.
* **Level 2** *(Configurable)*: Prerequisite libraries are not available in a centralized location but are expected to install successfully; code builds; full testing of model.
* **Level 3** *(Limited-test platforms)*: Libraries and code build on these systems, but there is limited testing of the model.
* **Level 4** *(Build-only platforms)*: Libraries and code build, but running the model is not tested.

Level 1 Systems
==================
Preconfigured (Level 1) systems for Land DA already have the required external libraries available in a central location via the :term:`spack-stack` Unified Environment (UE) and the ``jedi-bundle`` (Skylab v3.0). Land DA is expected to build and run out-of-the-box on these systems, and users can download the Land DA code without first installing prerequisite software. With the exception of the Land DA container, users must have access to these Level 1 systems in order to use them. 

+-----------+-----------------------------------+-----------------------------------------------------------------------------------+
| Platform  | Compiler/MPI                      | spack-stack & jedi-bundle Installations                                           |
+===========+===================================+===================================================================================+
| Hera      | intel/2022.1.2 /                  | /scratch1/NCEPDEV/nems/role.epic/spack-stack/spack-stack-1.3.0/envs/unified-env   |
|           |                                   |                                                                                   |
|           | impi/2022.1.2                     | /scratch1/NCEPDEV/nems/role.epic/contrib/jedi-bundle                              |
+-----------+-----------------------------------+-----------------------------------------------------------------------------------+
| Orion     | intel/2022.1.2 /                  | /work/noaa/epic-ps/role-epic-ps/spack-stack/spack-stack-1.3.0/envs/unified-env    |
|           |                                   |                                                                                   |
|           | impi/2022.1.2                     | /work/noaa/epic-ps/role-epic-ps/contrib/jedi-bundle                               |
+-----------+-----------------------------------+-----------------------------------------------------------------------------------+
| Container | intel-oneapi-compilers/2021.8.0 / | /opt/spack-stack/ (inside the container)                                          |
|           |                                   |                                                                                   |
|           | intel-oneapi-mpi/2021.8.0         | /opt/jedi-bundle (inside the container)                                           |
+-----------+-----------------------------------+-----------------------------------------------------------------------------------+

Level 2-4 Systems
===================

On non-Level 1 platforms, the Land DA System can be run within a container that includes the prerequisite software; otherwise, the required libraries will need to be installed as part of the Land DA build process. Once these prerequisite libraries are installed, applications and models should build and run successfully. However, users may need to perform additional troubleshooting on Level 3 or 4 systems since little or no pre-release testing has been conducted on these systems.

.. note::

   Running on Jet, Cheyenne, and NOAA Cloud systems is supported via container. 

Code Repositories and Directory Structure
********************************************

Directory Structure
======================

The main repository for the Land DA System is named ``land-DA_workflow``; 
it is available on GitHub at https://github.com/ufs-community/land-DA_workflow. 
A number of submodules are nested under the main ``land-DA_workflow`` directory. 
When the ``develop`` branch of the ``land-DA_workflow`` repository 
is cloned with the ``--recursive`` argument, the basic directory structure will be 
similar to the example below. Some files and directories have been removed for brevity. 
Directories in parentheses () are only visible after the build step. 

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
    ├── (ufs-weather-model)
    ├── vector2tile
    ├── CMakeLists.txt
    ├── README.md
    ├── LICENSE
    ├── check_*
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
   | land-DA_update           | Contains scripts and components for     | https://github.com/ufs-community/land-DA/            |
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

The UFS Land Component
=========================

The UFS Land DA System has been updated to build the UFS Noah-MP land component as part of the build process. 
Updates allowing the Land DA System to run with the land component are underway. 

The land component makes use of a National Unified Operational Prediction Capability (:term:`NUOPC`) cap to interface with a coupled modeling system. 
Unlike the standalone Noah-MP land driver, the Noah-MP :term:`NUOPC cap` is able to create an :term:`ESMF` multi-tile grid by reading in a mosaic grid file. For the domain, the :term:`FMS` initializes reading and writing of the cubed-sphere tiled output. Then, the Noah-MP land component reads static information and initial conditions (e.g., surface albedo) and interpolates the data to the date of the simulation. The solar zenith angle is calculated based on the time information. 




