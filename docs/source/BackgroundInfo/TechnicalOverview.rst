.. _TechOverview:

*********************
Technical Overview
*********************

.. _prerequisites:

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
   * `spack-stack <https://github.com/JCSDA/spack-stack>`__
   * `jedi-bundle <https://github.com/JCSDA/jedi-bundle>`__ (Skylab v4.0)

These software prerequisites are pre-installed in the Land DA :term:`container` and on other Level 1 systems (see :ref:`below <LevelsOfSupport>` for details). However, users on non-Level 1 systems will need to install them.

Before using the Land DA container, users will need to install `Singularity/Apptainer <https://apptainer.org/docs/admin/1.2/installation.html>`__ and an **Intel** MPI (available `free here <https://www.intel.com/content/www/us/en/developer/tools/oneapi/hpc-toolkit-download.html>`__). 


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
Preconfigured (Level 1) systems for Land DA already have the required external libraries available in a central location via :term:`spack-stack` and the ``jedi-bundle`` (Skylab v4.0). Land DA is expected to build and run out-of-the-box on these systems, and users can download the Land DA code without first installing prerequisite software. With the exception of the Land DA container, users must have access to these Level 1 systems in order to use them. 

.. COMMENT: Update spack-stack to 1.5.1

+-----------+-----------------------------------+-----------------------------------------------------------------+
| Platform  | Compiler/MPI                      | spack-stack & jedi-bundle Installations                         |
+===========+===================================+=================================================================+
| Hera      | intel/2022.1.2 /                  | /scratch1/NCEPDEV/nems/role.epic/spack-stack/spack-stack-1.3.0  |
|           |                                   |                                                                 |
|           | impi/2022.1.2                     | /scratch2/NAGAPE/epic/UFS_Land-DA/jedi/jedi-bundle              |
+-----------+-----------------------------------+-----------------------------------------------------------------+
| Orion     | intel/2022.1.2 /                  | /work/noaa/epic/role-epic/spack-stack/orion/spack-stack-1.3.0   |
|           |                                   |                                                                 |
|           | impi/2022.1.2                     | /work/noaa/epic/UFS_Land-DA/jedi/jedi-bundle                    |
+-----------+-----------------------------------+-----------------------------------------------------------------+
| Container | intel-oneapi-compilers/2021.8.0 / | /opt/spack-stack/ (inside the container)                        |
|           |                                   |                                                                 |
|           | intel-oneapi-mpi/2021.8.0         | /opt/jedi-bundle (inside the container)                         |
+-----------+-----------------------------------+-----------------------------------------------------------------+

Level 2-4 Systems
===================

On non-Level 1 platforms, the Land DA System can be run within a container that includes the prerequisite software; otherwise, the required libraries will need to be installed as part of the Land DA build process. Once these prerequisite libraries are installed, applications and models should build and run successfully. However, users may need to perform additional troubleshooting on Level 3 or 4 systems since little or no pre-release testing has been conducted on these systems.

.. _repos-dir-structure:

Code Repositories and Directory Structure
********************************************

.. _file-dir-structure:

File & Directory Structure
============================

The main repository for the Land DA System is named ``land-DA_workflow``; 
it is available on GitHub at https://github.com/ufs-community/land-DA_workflow. 
The ``land-DA_workflow`` is evolving to follow the :term:`NCEP` Central Operations (NCO) `WCOSS Implementation Standards <https://www.nco.ncep.noaa.gov/idsb/implementation_standards/ImplementationStandards.v11.0.0.pdf>`__. This structure is implemented using Git submodules. When the ``develop`` branch of the ``land-DA_workflow`` repository is cloned with the ``--recursive`` argument, the specific GitHub repositories described in ``/sorc/app_build.sh`` are cloned into ``sorc``. The diagram below illustrates the file and directory structure of the Land DA System. Directories in parentheses () are only visible after the build step. Some files and directories have been removed for brevity. 

.. COMMENT: Add parentheses around post-build dirs and update language above

.. code-block:: console

   land-offline_workflow
    ├── configures
    ├── doc
    ├── jobs
    ├── modulefiles
    ├── parm
    ├── sorc
    │     ├── DA_update
    │     │     ├── add_jedi_incr
    │     │     ├── jedi/fv3-jedi
    │     │     └── do_LandDA.sh
    │     ├── cmake
    │     ├── test
    │     ├── tile2tile_converter.fd --- Tile-to-tile converter
    │     │     ├── cmake
    │     │     └── config
    │     ├── ufsLand.fd           ----- UFS Land Driver (ufs-land-driver-emc-dev)
    │     │     └── ccpp-physics
    │     ├── ufs_model.fd         ----- UFS Weather Model (ufs-weather-model)
    │     └── vector2tile_converter.fd - Vector-to-tile converter
    │     │     ├── cmake
    │     │     └── config
    │     ├── CMakeLists.txt
    │     └── app_build.sh
    ├── LICENSE
    ├── README.md
    ├── check_*
    ├── datm_cdeps_lnd_gswp3_rst
    ├── do_submit_cycle.sh
    ├── do_submit_test.sh
    ├── fv3_run
    ├── incdate.sh
    ├── land_mods
    ├── module_check.sh
    ├── release.environment
    ├── run_container_executable.sh
    ├── settings_DA_*
    └── submit_cycle.sh

:numref:`Table %s <Subdirectories>` describes the contents of the most important Land DA subdirectories. :numref:`Section %s <components>` describes the Land DA System components. Users can reference the `NCO Implementation Standards <https://www.nco.ncep.noaa.gov/idsb/implementation_standards/ImplementationStandards.v11.0.0.pdf>`__ (p. 19) for additional details on repository structure in NCO-compliant repositories. 

.. _Subdirectories:

.. list-table:: *Subdirectories of the land-DA_workflow repository*
   :widths: 20 50
   :header-rows: 1

   * - Directory Name
     - Description
   * - configures
     - Machine-specific configurations
   * - docs
     - Repository documentation
   * - jobs
     - :term:`J-job <J-jobs>` scripts launched by Rocoto
   * - modulefiles
     - Files that load the modules required for building and running the workflow
   * - parm
     - Parameter files used to configure the model, physics, workflow, and various components
   * - sorc
     - External source code used to build the Land DA System

.. COMMENT: Update "configures" description?

.. COMMENT: Add later?   
   * - scripts
     - Scripts launched by the J-jobs
   * - tests
     - Tests for baseline experiment configurations

.. _components:

Land DA Components
=====================

:numref:`Table %s <LandDAComponents>` describes the various subrepositories that form the UFS Land DA System. 

.. _LandDAComponents:

.. list-table:: UFS Land DA System Components
   :header-rows: 1

   * - Repository Name
     - Repository Description
     - Authoritative Repository URL
   * - DA_update
     - Contains scripts and components for performing data assimilation (DA) procedures.
     - https://github.com/ufs-community/land-DA/
   * - *-- land-apply_jedi_incr*
     - Contains code that applies the JEDI-generated DA increment to UFS ``sfc_data`` restart 
     - https://github.com/NOAA-PSL/land-apply_jedi_incr
   * - ufs-land-driver-emc-dev
     - Repository for the UFS Land Driver
     - https://github.com/NOAA-EPIC/ufs-land-driver-emc-dev
   * - *-- ccpp-physics*
     - Repository for the Common Community Physics Package (CCPP)
     - https://github.com/ufs-community/ccpp-physics/
   * - land-vector2tile
     - Contains code to map between the vector format used by the Noah-MP offline driver, and the tile format used by the UFS atmospheric model. 
     - https://github.com/NOAA-PSL/land-vector2tile

.. _land-component:

The UFS Land Component
=========================

The UFS Land DA System has been updated to build the UFS Noah-MP land component as part of the build process. 
Updates allowing the Land DA System to run with the land component are underway. 

The land component makes use of a National Unified Operational Prediction Capability (:term:`NUOPC`) cap to interface with a coupled modeling system. 
Unlike the standalone Noah-MP land driver, the Noah-MP :term:`NUOPC cap` is able to create an :term:`ESMF` multi-tile grid by reading in a mosaic grid file. For the domain, the :term:`FMS` initializes reading and writing of the cubed-sphere tiled output. Then, the Noah-MP land component reads static information and initial conditions (e.g., surface albedo) and interpolates the data to the date of the simulation. The solar zenith angle is calculated based on the time information. 
