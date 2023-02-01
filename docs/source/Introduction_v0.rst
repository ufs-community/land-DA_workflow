.. _Intro:

================
Introduction
================

This User's Guide provides guidance for running the Unified Forecast System 
(:term:`UFS`) land model. This land model is the Multi-Physics (MP) version of the 
Noah land surface model (LSM) used by NOAA (referred to as Noah-MP). Its data assimilation framework uses 
the Joint Effort for Data assimilation Integration (:term:`JEDI`) software.
Noah-MP is tightly coupled with the atmospheric component of the 
`UFS Weather Model <https://github.com/ufs-community/ufs-weather-model>`__, 
and is essentially a module/subroutine within the `Common Community Physics Package
(CCPP) <https://dtcenter.org/community-code/common-community-physics-package-ccpp>`__
repository. The UFS Land DA System currently only works with snow data. Thus,
this User's Guide focuses primarily on the snow DA process.

Background Information
=========================

Unified Forecast System
--------------------------

The Unified Forecast System (:term:`UFS`) is a community-based, coupled, comprehensive Earth modeling system. NOAA’s operational model suite for numerical weather prediction (:term:`NWP`) is quickly transitioning to the UFS from many different modeling systems. For example, the UFS-based Global Forecast System
(`GFS <https://www.emc.ncep.noaa.gov/emc/pages/numerical_forecast_systems/gfs.php>`__)
and the Global Ensemble Forecast System
(`GEFS <https://www.emc.ncep.noaa.gov/emc/pages/numerical_forecast_systems/gefs.php>`__) are currently in operational use.
The UFS enables research, development, and contribution
opportunities within the broader :term:`Weather Enterprise` (including
government, industry, and academia). 

Currently, the UFS Weather Model includes: 

   * The `FV3 <https://www.gfdl.noaa.gov/fv3/>`__ dynamical core with the Common Community Physics Package (`CCPP <https://dtcenter.ucar.edu/gmtb/users/ccpp/docs/sci_doc_v2/>`__) for atmospheric modeling, 
   * The `MOM6 <https://github.com/NOAA-GFDL/MOM6>`__ ocean model,
   * The `GOCART <https://gmao.gsfc.nasa.gov/research/aerosol/modeling/>`__ aerosols model, 
   * The `CICE6 <https://github.com/CICE-Consortium/CICE>`__ sea ice model, and 
   * The `WW3 <https://polar.ncep.noaa.gov/waves/wavewatch/>`__ ocean wave model. 

Noah, Noah-MP, and Rapid Update Cycle (RUC) land models are
currently available options within the CCPP framework, and the CCPP
modules are assumed to be one-dimensional (1-D) column models. 
Since the GFSv17 updates, Noah LSM (widely used, bulk surface treatment) has been replaced with Noah-MP LSM (explicit canopy, process-based, see details in :numref:`Section %s <NoahMP>`). 
This transition will contribute to: 

   #. improving surface forecasts when significant heterogeneities exist, 
   #. looking beyond the LSM as a boundary condition, 
   #. providing multiple land surface process-level information, and 
   #. increasing both atmospheric and land surface DA. 

For more information about the UFS, visit the `UFS Portal <https://ufscommunity.org/>`__.

.. _NoahMP:

History of Noah MP
--------------------

Noah is a land surface model (LSM) that has evolved through community
efforts for pursuing and refining a modern-era LSM suitable for use in
National Centers for Environmental Prediction (NCEP) operational weather
and climate prediction models. In the 1990s, the Environmental Modeling
Center (EMC) of NCEP chose the OSU LSM (:cite:t:`Mahrt&Pan1984`) due to
its good performance and pre-existing hands-on experience with this LSM
by various EMC staff members after NCEP carried out an intercomparison
of four LSMS, including 1) a simple bucket model, 2) the OSU LSM, 3) the
simplified Simple Biosphere Model (SSiB) model, and 4) the Simple Water
Balance model (SWB) of OH (:cite:t:`ChenEtAl1996`). NCEP used the Noah for
further refinement and implementation in NCEP regional and global
coupled weather and climate models and their companion data assimilation
systems. In 2000, given a) the advent of the "New Millenium", b) a
strong desire by EMC to better recognize its LSM collaborators, and c) a
new NCEP goal to more strongly pursue and offer "Community Models", EMC
decided to coin the new name "NOAH" for the LSM that had emerged at NCEP
during the 1990s. 

   * **N:** National Centers for Environmental Prediction (NCEP)
   * **O:** Oregon State University (Dept of Atmospheric Sciences)
   * **A:** Air Force (both Air Force Weather Agency (AFWA) and Air Force Research Lab (AFRL) --- formerly AFGL, PL)
   * **H:** Hydrology Lab –-- NWS (National Weather Service, formerly Office of Hydrology –-- OH)

With the choice of the "NOAH" acronym, EMC strived to explicitly acknowledge 
both the multi-group heritage and
informal "community" usage of this LSM, going back to the early 1980s.
Since its beginning then at Oregon State University, the evolution of
the present NOAH LSM herein has spanned significant ongoing development
efforts by the above groups.

Noah LSM is a stand-alone, uncoupled, 1-D column version used to execute
single-site land surface simulations. In this traditional 1-D uncoupled
mode, near-surface atmospheric forcing data is required as input
forcing. This LSM simulates soil moisture (both liquid and frozen), soil
temperature, skin temperature, snow depth, snow water equivalent (SWE),
snow density, canopy water content, and the energy flux and water flux
terms of the surface energy balance and surface water balance. Noah LSM
has been extensively evaluated in both the offline mode and the coupled
mode. More detailed descriptions of Noah physics and developments are
presented by :cite:t:`EkEtAl2003` 2003 and :cite:t:`KorenEtAl1999` 1999.

Noah-MP is currently used operationally at the NOAA National Water Model
(NWM) which is built upon the legacy of the Noah model, but with new and
multiple options for selected processes: 1) restructuring the model to
include a separated vegetation canopy accounting for vegetation effects
on surface energy and water balances, 2) a modified two-stream
approximation scheme to include the effects of vegetation canopy gaps
that vary with solar zenith angle and the canopy 3-D structure on
radiation transfer, 3) a 3-layer physically-based snow model, 4) a more
permeable frozen soil by separating a grid cell into a permeable
fraction and impermeable fraction, 5) a simple groundwater model with a
TOPMODEL-based runoff scheme, and 6) a short-term leaf phenology model.
Multiple parameterizations are the key to treating
hydrology-snow-vegetation processes in a single land modeling framework
and structural differences improve performance over heterogeneous
surfaces. In addition, Noah-MP LSM enables a modular framework for
diagnosing differences in process representation, facilitating ensemble
forecasts and uncertainty quantification, and choosing process
presentations appropriate for the application. On the basis of the
modified Noah, the developers designed options of schemes for leaf
dynamics, radiation transfer, stomatal resistance, soil moisture stress
factor for stomatal resistance, aerodynamic resistance, runoff,
snowfall, snow surface albedo, supercooled liquid water in frozen soil,
and frozen soil permeability, etc. A collaborative effort among NCAR,
NCEP, NASA, and university groups has been established to develop and
improve the community Noah-MP LSM. Details about the model's physical
parameterizations can be referred to Niu et al. [2011].

.. COMMENT: Need a citation for Niu et al (2011)! 


Code Repositories and Directory Structure
==============================================

Directory Structure
----------------------

The main repository for the Land DA System is named ``land-offline_workflow``; 
it is available on GitHub at https://github.com/NOAA-PSL/land-offline_workflow. 
A number of submodules are nested under the main ``land-offline_workflow`` directory. 
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

   +--------------------------+-----------------------------------------+------------------------------------------------------+
   | Repository Name          | Repository Description                  | Authoritative repository URL                         |
   +==========================+=========================================+======================================================+
   | land-DA_update           | Contains scripts and components for     | https://github.com/NOAA-PSL/land-DA_update           |
   |                          | performing data assimilation (DA)       |                                                      |
   |                          | procedures.                             |                                                      |
   +--------------------------+-----------------------------------------+------------------------------------------------------+
   |   *land-apply_jedi_incr* | Contains code that applies the          | https://github.com/NOAA-PSL/land-apply_jedi_incr     |
   |                          | JEDI-generated DA increment to UFS      |                                                      |
   |                          | ``sfc_data`` restart                    |                                                      |
   +--------------------------+-----------------------------------------+------------------------------------------------------+
   |   *land-IMS_proc*        | Contains code for processing Ice        | https://github.com/NOAA-PSL/land-IMS_proc            |
   |                          | Mapping Data (IMS) ASCII input files    |                                                      |
   |                          | on the UFS model grid.                  |                                                      |
   +--------------------------+-----------------------------------------+------------------------------------------------------+
   | ufs-land-driver          | Repository for the UFS Land             | https://github.com/barlage/ufs-land-driver           | 
   |                          | Driver                                  |                                                      |
   +--------------------------+-----------------------------------------+------------------------------------------------------+
   |   - *ccpp-physics*       | Repository for the Common               | https://github.com/NCAR/ccpp-physics                 |
   |                          | Community Physics Package (CCPP)        |                                                      |
   |                          |                                         |                                                      |
   +--------------------------+-----------------------------------------+------------------------------------------------------+
   | land-vector2tile         | Contains code to map between the vector | https://github.com/NOAA-PSL/land-vector2tile         |
   |                          | format used by the Noah-MP offline      |                                                      |
   |                          | driver, and the tile format used by the |                                                      |
   |                          | UFS atmospheric model.                  |                                                      |
   +--------------------------+-----------------------------------------+------------------------------------------------------+


Disclaimer 
==============

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

References
============

.. bibliography:: references.bib