.. _Intro:

================
Introduction
================

This User's Guide provides guidance for running the Unified Forecast System 
(:term:`UFS`) land model. This land model is the Multi-Physics (MP) version of the 
Noah land surface model used by NOAA (Noah-MP). Its data assimilation framework uses 
the Joint Effort for Data assimilation Integration (:term:`JEDI`) software.
Noah-MP is tightly coupled with the atmospheric component of the 
`UFS Weather Model <https://github.com/ufs-community/ufs-weather-model>`__, 
and it is essentially a module/subroutine within the `Common Community Physics Package
(CCPP) <https://dtcenter.org/community-code/common-community-physics-package-ccpp>`__
repository. The UFS Land DA System currently only works with snow data. Thus,
this User's Guide focuses primarily on the snow DA process.

Code Repositories and Directory Structure
==============================================

Directory Structure
----------------------

The main repository for the Land DA System is named ``land-offline_workflow`` 
and is available on GitHub at https://github.com/NOAA-PSL/land-offline_workflow. 
Under this repository reside a number of submodules that are nested in specific 
directories under the parent repository's working directory. 
When the ``land-offline_workflow`` repository is cloned with the 
``--recurse-submodules`` argument, the basic directory structure will be similar 
to the example below. Some files and directories have been removed for brevity. 

.. COMMENT: Update GitHub link later to reflect NOAA-EPIC location.

.. code-block:: console

   land-offline_workflow
    ├── DA_update
    │     ├── IMS_proc
    │     ├── add_jedi_incr
    │     └── jedi
    ├── cmake
    ├── configures
    ├── docs 
    ├── ensemble_pert
    ├── ufs-land-driver
    │     └── ccpp-physics
    ├── vector2tile
    ├── CMakeLists.txt
    └── README.md

Land DA Components
---------------------

:numref:`Table %s <LandDAComponents>` describes the various subrepositories that form
the UFS Land DA System. 

.. _LandDAComponents:

.. table:: UFS Land DA System Components

   +------------------------+-----------------------------------------+------------------------------------------------------+
   | Repository Name        | Repository Description                  | Authoritative repository URL                         |
   +========================+=========================================+======================================================+
   | land-DA_update         | Contains scripts and components for     | https://github.com/NOAA-PSL/land-DA_update           |
   |                        | performing data assimilation (DA)       |                                                      |
   |                        | procedures.                             |                                                      |
   +------------------------+-----------------------------------------+------------------------------------------------------+
   | - land-apply_jedi_incr | Contains code that applies the          | https://github.com/NOAA-PSL/land-apply_jedi_incr     |
   |                        | JEDI-generated DA increment to UFS      |                                                      |
   |                        | ``sfc_data`` restart                    |                                                      |
   +------------------------+-----------------------------------------+------------------------------------------------------+
   | - land-IMS_proc        | Contains code for processing Ice        | https://github.com/NOAA-PSL/land-IMS_proc            |
   |                        | Mapping Data (IMS) ASCII input files    |                                                      |
   |                        | on the UFS model grid.                  |                                                      |
   +------------------------+-----------------------------------------+------------------------------------------------------+
   | ufs-land-driver        | Repository for the UFS Land             | https://github.com/barlage/ufs-land-driver           | 
   |                        | Driver                                  |                                                      |
   |                        |                                         |                                                      |
   +------------------------+-----------------------------------------+------------------------------------------------------+
   | - ccpp-physics         | Repository for the Common               | https://github.com/NCAR/ccpp-physics                 |
   |                        | Community Physics Package (CCPP)        |                                                      |
   |                        |                                         |                                                      |
   +------------------------+-----------------------------------------+------------------------------------------------------+
   | land-vector2tile       | Contains code to map between the vector | https://github.com/NOAA-PSL/land-vector2tile         |
   |                        | format used by the Noah-MP offline      |                                                      |
   |                        | driver, and the tile format used by the |                                                      |
   |                        | UFS atmospheric model.                  |                                                      |
   +------------------------+-----------------------------------------+------------------------------------------------------+


Disclaimer 
================

The United States Department of Commerce (DOC) GitHub project code is
provided on an “as is” basis and the user assumes responsibility for its
use. DOC has relinquished control of the information and no longer has a
responsibility to protect the integrity, confidentiality, or
availability of the information. Any claims against the Department of
Commerce stemming from the use of its GitHub project will be governed by
all applicable Federal laws. Any reference to specific commercial
products, processes, or services by service mark, trademark,
manufacturer, or otherwise, does not constitute or imply their
endorsement, recommendation, or favoring by the Department of Commerce.
The Department of Commerce seal and logo, or the seal and logo of a DOC
bureau, shall not be used in any manner to imply endorsement of any
commercial product or activity by DOC or the United States Government.

.. bibliography:: references.bib

.. COMMENT: 

   References
   ==========

   Chen, F., Mitchell, K., Schaake, J., Xue, Y., Pan, H.L., Koren,
   V., Duan, Q.Y., Ek, M. and Betts, A
   Modeling of land surface evaporation by four schemes and comparison with FIFE
   observations.
   Journal of Geophysical Research Atmospheres, 101(D3), 
   pp.7251-7268, 1996.

   Ek, M. B., Mitchell, K. and Y. Lin 
   Implementation of Noah land surface model advances in the National Centers for Environmental Prediction
   operational mesoscale Eta model, 
   Journal of Geophysical Research,
   108(D22), 
   doi:10.1029/2002JD003296, 
   2003.

   Koren, V., Schaake, J., Mitchell, K., Duan, Q. Y., Chen, F. and Baker,
   J. M.: A parameterization of snowpack and frozen ground intended for
   NCEP weather and climate models, Journal of Geophysical Research
   Atmospheres, 104(D16), 19569- 19585, doi:10.1029/1999JD900232, 1999.

   Mahrt, L. and Pan, H.: A two-layer model of soil hydrology,
   Boundary-Layer Meteorology, 29(1), 1-20, doi:10.1007/BF00119116, 1984.
