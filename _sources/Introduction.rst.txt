.. _Intro:

****************
Introduction
****************

This User's Guide provides guidance for running the Unified Forecast System 
(:term:`UFS`) offline Land Data Assimilation (DA) System. Land DA is an offline version of the Noah Multi-Physics (Noah-MP) land surface model (LSM) used in the `UFS Weather Model <https://github.com/ufs-community/ufs-weather-model>`__ (WM). Its data assimilation framework uses 
the Joint Effort for Data assimilation Integration (:term:`JEDI`) software. The offline UFS Land Data Assimilation (Land DA) System currently only works with snow data. 
Thus, this User's Guide focuses primarily on the snow DA process.

This User's Guide is organized as follows:

   * This chapter (Introduction) provides background information on the Unified Forecast System (:term:`UFS`) and the NoahMP model. 
   * :numref:`Chapter %s <TechOverview>` (Technical Overview) outlines prerequisites, user support levels, and directory structure. 
   * :numref:`Chapter %s <BuildRunLandDA>` (Land DA Workflow [Hera & Orion]) explains how to build and run the Land DA System on :ref:`Level 1 <LevelsOfSupport>` systems (currently Hera and Orion).
   * :numref:`Chapter %s <Container>` (Land DA Workflow [in a Container]) explains how to build and run the containerized Land DA System on non-Level 1 systems. 
   * :numref:`Chapter %s <Model>` (Model) provides information on input data and configuration parameters in the Noah-MP LSM and its Vector-to-Tile Converter.
   * :numref:`Chapter %s <DASystem>` (DA Framework) provides information on the DA system, required data, and configuration parameters. 
   * :numref:`Chapter %s <Glossary>` (Glossary) lists important terms. 

Users and developers may post questions and exchange information on the Land DA System's `GitHub Discussions <https://github.com/ufs-community/land-DA_workflow/discussions/categories/q-a>`__ forum if their concerns are not addressed in this User's Guide.

The Land DA System citation is as follows and should be used when presenting results based on research conducted with the Land DA System:

UFS Development Team. (2023, March 6). Unified Forecast System (UFS) Land Data Assimilation (DA) System (Version v1.0.0). Zenodo. https://doi.org/10.5281/zenodo.7675721


.. _Background:

Background Information
************************

Unified Forecast System (UFS)
===============================

The UFS is a community-based, coupled, comprehensive Earth modeling system. It includes `multiple applications <https://ufscommunity.org/science/aboutapps/>`__ that support different forecast durations and spatial domains. NOAA's operational model suite for numerical weather prediction (:term:`NWP`) is quickly transitioning to the UFS from many different modeling systems. For example, the UFS-based Global Forecast System
(`GFS <https://www.emc.ncep.noaa.gov/emc/pages/numerical_forecast_systems/gfs.php>`__)
and the Global Ensemble Forecast System
(`GEFS <https://www.emc.ncep.noaa.gov/emc/pages/numerical_forecast_systems/gefs.php>`__) are currently in operational use.
The UFS is designed to enable research, development, and contribution
opportunities within the broader :term:`Weather Enterprise` (including
government, industry, and academia). For more information about the UFS, visit the `UFS Portal <https://ufscommunity.org/>`__.


.. _NoahMP:

Noah-MP
==========

The offline Noah-MP LSM is a stand-alone, uncoupled model used to execute land surface simulations. In this traditional uncoupled mode, near-surface atmospheric :term:`forcing data` are required as input forcing. This LSM simulates soil moisture (both liquid and frozen), soil temperature, skin temperature, snow depth, snow water equivalent (SWE), snow density, canopy water content, and the energy flux and water flux terms of the surface energy balance and surface water balance.

Noah-MP uses a big-leaf approach with a separated vegetation canopy accounting 
for vegetation effects on surface energy and water balances, a modified two-stream 
approximation scheme to include the effects of vegetation canopy gaps that vary 
with solar zenith angle and the canopy 3-D structure on radiation transfer, 
a 3-layer physically-based snow model, a more permeable frozen soil by separating 
a grid cell into a permeable fraction and impermeable fraction, a simple 
groundwater model with a TOPMODEL-based runoff scheme, and a short-term leaf 
phenology model. Noah-MP LSM enables a modular framework for diagnosing differences 
in process representation, facilitating ensemble forecasts and uncertainty 
quantification, and choosing process presentations appropriate for the application. 
Noah-MP developers designed multiple parameterization options for leaf dynamics, 
radiation transfer, stomatal resistance, soil moisture stress factor for stomatal 
resistance, aerodynamic resistance, runoff, snowfall, snow surface albedo, 
supercooled liquid water in frozen soil, and frozen soil permeability. 

The Noah-MP LSM has evolved through community efforts to pursue and refine a modern-era LSM suitable for use in the National Centers for Environmental Prediction (NCEP) operational weather and climate prediction models. This collaborative effort continues with participation from entities such as NCAR, NCEP, NASA, and university groups. 

Noah-MP has been implemented in the UFS via the :term:`CCPP` physics package and 
is currently being tested for operational use in GFSv17 and RRFS v2. Noah-MP has 
also been used operationally in the NOAA National Water Model (NWM) since 2016. Details about the model's physical parameterizations can be found in :cite:t:`NiuEtAl2011` (2011). 

Disclaimer 
*************

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
*************

.. bibliography:: references.bib