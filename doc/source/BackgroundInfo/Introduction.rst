.. _Intro:

****************
Introduction
****************

Unified Forecast System (UFS)
===============================

The UFS is a community-based, coupled, comprehensive Earth modeling system. It includes :ufs:`multiple applications <applications>` that support different forecast durations and spatial domains. NOAA's operational model suite for numerical weather prediction (:term:`NWP`) is transitioning to the UFS from many different modeling systems. 
The UFS is designed to enable research, development, and contribution
opportunities within the broader :term:`Weather Enterprise` (including
government, industry, and academia). For more information about the UFS, visit the :ufs:`UFS Portal <>`.

The Land DA System
====================

This User's Guide provides guidance for running the Unified Forecast System 
(:term:`UFS`) Land Data Assimilation (:term:`DA`) System. Land DA uses the Noah Multi-Physics (Noah-MP) land surface model (LSM) from the `UFS Weather Model <https://github.com/ufs-community/ufs-weather-model>`_ (WM), which can be coupled with an active atmospheric component (:term:`FV3`) or the WM data atmosphere component (:term:`DATM`) if desired. Its data assimilation framework uses 
the Joint Effort for Data assimilation Integration (:term:`JEDI`) software. Currently, the UFS Land DA System only works with snow and soil moisture data. 
Thus, this User's Guide focuses primarily on the snow and soil moisture DA processes.

The following improvements have been made to the Land DA System since the |latestr| release:

* Support for a new coupling option --- :term:`LND` (Noah-MP) and :term:`ATM` (FV3) --- (:land-wflow-repo:`PR #171 <pull/171/>`)
* Support for soil moisture data assimilation (PRs :land-wflow-repo:`#239 <pull/239/>`, :land-wflow-repo:`#246 <pull/246/>`, :land-wflow-repo:`#255 <pull/255/>`, :land-wflow-repo:`#259 <pull/259/>`, :land-wflow-repo:`#263 <pull/263/>`)
* Addition of 3DVar to JEDI algorithm (:land-wflow-repo:`PR #187 <pull/187/>`)
* Integration of the JEDI Configuration Builder (:term:`JCB`) into Land DA System (:land-wflow-repo:`PR #182 <pull/182/>`)
* Creation of JEDI configuration/input files (:land-wflow-repo:`PR #182 <pull/182/>`) for LETKF-OI (:land-wflow-repo:`PR #190 <pull/190/>`) and 3DVar (:land-wflow-repo:`PR #188 <pull/188/>`) using :term:`JCB`
* Inclusion of `jcb-algorithms <https://github.com/NOAA-EPIC/jcb-algorithms>`_ and `jcb-gdas <https://github.com/NOAA-EPIC/jcb-gdas>`_ as Land DA submodules to facilitate DA configuration with JCB (:land-wflow-repo:`PR #179 <pull/179/>`)
* Addition of capability to use :term:`IMS` snow observation data by converting it to NetCDF form in the ``prep_data`` workflow task (:land-wflow-repo:`PR #222 <pull/222/>`) ; improvements to IMS data processing capabilities (:land-wflow-repo:`PR #224 <pull/224/>`)
* Addition of :term:`ERA5` forcing option for ``APP=LND`` (:land-wflow-repo:`PR #214 <pull/214/>`); improvement of ERA5 data processing capabilities (:land-wflow-repo:`PR #219 <pull/219/>`)
* Update CCPP physics suite for ``APP=ATML`` from ``FV3_GFS_v17_p8`` to ``FV3_GFS_v17_p8_ugwpv1`` (:land-wflow-repo:`PR #216 <pull/216/>`)
* Expansion of Land DA :ref:`Level 1 <level1>` support to Gaea C6 (:land-wflow-repo:`PR #211 <pull/211/>`) and Ursa (:land-wflow-repo:`PR #256 <pull/256/>`)
* Container support for Gaea C6 (:land-wflow-repo:`PR #177 <pull/177/>`)
* Enhancements to plotting functionality (PRs :land-wflow-repo:`#192 <pull/192/>` & :land-wflow-repo:`#235 <pull/235/>`)
* Replace JEDI Skylab with GDAS-sync'd JEDI-bundle (PRs :land-wflow-repo:`#203 <pull/203/>` & :land-wflow-repo:`#209 <pull/209/>`)
* Upgrade to spack-stack v1.9.2 (:land-wflow-repo:`PR #253 <pull/253/>`)
* Update submodule hashes (PRs :land-wflow-repo:`#200 <pull/200/>`, :land-wflow-repo:`#275 <pull/275/>`, :land-wflow-repo:`#277 <pull/277/>`, :land-wflow-repo:`PR <pull/279/>`)
* Add sample configurations for CADRE DA training (:land-wflow-repo:`PR #227 <pull/227/>`)
* Update Land DA ``develop`` branch container (:land-wflow-repo:`PR #228 <pull/228/>`)
* Jenkins CI/CD pipeline and testing improvements (PRs :land-wflow-repo:`#174 <pull/174/>`, :land-wflow-repo:`#199 <pull/199/>`, :land-wflow-repo:`#225 <pull/225/>`, :land-wflow-repo:`#229 <pull/229/>`)
* Add Ursa to metrics calculations (:land-wflow-repo:`PR #280 <pull/280/>`)
* Bug fixes, minor updates, and refactoring since the |latestr| release (PRs :land-wflow-repo:`#184 <pull/184/>`, :land-wflow-repo:`#191 <pull/191/>`, :land-wflow-repo:`#195 <pull/195/>`, :land-wflow-repo:`#197 <pull/197/>`, :land-wflow-repo:`#205 <pull/205/>`, :land-wflow-repo:`#207 <pull/207/>`, :land-wflow-repo:`#217 <pull/217/>`, :land-wflow-repo:`#221 <pull/221/>`, :land-wflow-repo:`#230 <pull/230/>`, :land-wflow-repo:`#231 <pull/231/>`, :land-wflow-repo:`PR #237 <pull/237/>`, :land-wflow-repo:`PR #243 <pull/243/>`, :land-wflow-repo:`PR #262 <pull/262/>`, :land-wflow-repo:`PR #266 <pull/266/>`, :land-wflow-repo:`PR #268 <pull/268/>`, :land-wflow-repo:`PR #270 <pull/270/>`, :land-wflow-repo:`PR #271 <pull/271/>`, :land-wflow-repo:`PR #273 <pull/273/>`, :land-wflow-repo:`PR #281 <pull/281/>`, :land-wflow-repo:`PR #282 <pull/282/>`, :land-wflow-repo:`PR #283 <pull/283/>`, :land-wflow-repo:`PR #286 <pull/286/>`)


The Land DA System citation is as follows and should be used when presenting results based on research conducted with the Land DA System:

UFS Development Team. (2026, April 9). Unified Forecast System (UFS) Land Data Assimilation (DA) System (Version v3.0.0). Zenodo. https://doi.org/10.5281/zenodo.19135590

Organization of the Land DA User's Guide
==========================================

This User's Guide is organized into four sections: (1) *Background Information*; (2) *Building, Running, and Testing the Land DA System*; (3) *Customizing the Workflow*; and (4) *Reference*.

Background Information
------------------------
   * This chapter (Introduction) provides an overview of this user's guide, user support information, and a list of updates since the last release. 
   * :numref:`Chapter %s <TechOverview>` (Technical Overview) outlines prerequisites, supported systems, and directory structure for the Land DA System. 
   * :numref:`Chapter %s <Components>` (Components) describes the components that comprise the Land DA System. 

Building, Running, and Testing the Land DA System
---------------------------------------------------

   * :numref:`Chapter %s: Running the Land DA Workflow <BuildRunLandDA>` explains how to build and run the Land DA System on :ref:`Level 1 <LevelsOfSupport>` systems (currently Ursa, Orion, Hercules, and Gaea-C6).
   * :numref:`Chapter %s: Containerized Land DA Workflow <Container>` explains how to build and run the containerized Land DA System on non-Level 1 systems. 
   * :numref:`Chapter %s: Testing the Land DA Workflow <TestingLandDA>` explains how to run Land DA System tests. 

Customizing the Workflow
--------------------------

   * :numref:`Chapter %s: Available Workflow Configuration Parameters <ConfigWorkflow>` explains all of the user-configurable options currently available in the workflow configuration file (``land_analysis*.yaml``).
   * :numref:`Chapter %s: Input/Output Files for the Land DA System <IO>` provides information on input/output data for the Land DA System.
   * :numref:`Chapter %s: Joint Effort for Data Assimilation Integration (JEDI) DA System <DASystem>` provides information on the JEDI DA system and configuration parameters. 

Reference
-----------

   * :numref:`Chapter %s: Rocoto <RocotoInfo>` provides background information on the Rocoto workflow manager as used in Land DA.  
   * :numref:`Chapter %s: FAQ <FAQ>` addresses frequently asked questions. 
   * :numref:`Chapter %s: Glossary <Glossary>` lists important terms. 

User Support and Documentation
================================

Questions
-----------

The Land DA System's `GitHub Discussions <https://github.com/ufs-community/land-DA_workflow/discussions/categories/q-a>`_ forum provides online support for UFS users and developers to post questions and exchange information. When users encounter difficulties running the Land DA System, this is the place to post. Users can expect an initial response within two business days. 

When posting a question, it is recommended that users provide the following information: 

* The platform or system being used (e.g., Ursa, Hercules, container)
* The version of the Land DA System being used (e.g., ``develop``, ``release/public-v2.0.0``). (To determine this, users can run ``git branch``, and the name of the branch with an asterisk ``*`` in front of it is the name of the branch or tag they are working with.) Note that the Land DA version being used and the version of the documentation being used should match, or users will run into difficulties.
* Stage of the application when the issue appeared (i.e., build/compilation, configuration, or forecast run)
* Contents of relevant configuration files
* Full error message (preferably in text form rather than a screenshot)
* Current shell (e.g., bash, csh) and modules loaded
* Compiler + MPI combination being used
* Run directory and code directory, if available on supported platforms

Bug Reports
-------------

If users (especially new users) believe they have identified a bug in the system, it is recommended that they first ask about the problem in a :land-wflow-repo:`GitHub Discussions <discussions/categories/q-a>` post, since many "bugs" do not require a code change/fix --- instead, the user may be unfamiliar with the system and/or may have misunderstood some component of the system or the instructions, which is causing the problem. Asking for assistance in a :land-wflow-repo:`GitHub Discussion <discussions/categories/q-a>` post can help clarify whether there is a simple adjustment to fix the problem or whether there is a genuine bug in the code. Users are also encouraged to search :land-wflow-repo:`open issues <issues>` to see if their bug has already been identified. If there is a genuine bug, and there is no open issue to address it, users can report the bug by filing a :land-wflow-repo:`GitHub Issue <issues/new>`. 

Feature Requests and Enhancements
-----------------------------------

Users who want to request a feature enhancement or the addition of a new feature have a few options: 

   #. File a `GitHub Issue <https://github.com/ufs-community/land-DA_workflow/issues/new>`_ and add (or request that a code manager add) the ``EPIC Support Requested`` label. 
   #. Post a request for a feature or enhancement in the `Enhancements <https://github.com/ufs-community/land-DA_workflow/discussions/categories/enhancements>`_ category of GitHub Discussions. These feature requests will be forwarded to the Earth Prediction Innovation Center (`EPIC <https://epic.noaa.gov/>`_) management team for prioritization and eventual addition to the Land DA System. 
   #. Email the request to support.epic@noaa.gov. 

Disclaimer 
============

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

.. bibliography:: ../references.bib