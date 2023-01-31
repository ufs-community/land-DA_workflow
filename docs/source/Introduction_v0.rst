.. _Intro:

================
Introduction
================

This User's Guide provides execution guidance for the Unified Forecast System 
(:term:`UFS`) land model. This land model is the Multi-Physics (MP) version of the 
Noah land surface model used by NOAA (the current `UFS land
model <https://ufscommunity.org/>`__, hereinafter Noah-MP). Its data
assimilation framework uses the `Joint Effort for Data assimilation Integration
(JEDI) <https://jointcenterforsatellitedataassimilation-jedi-docs.readthedocs-hosted.com/en/latest/>`__.
Noah-MP is tightly coupled with the UFS atmospheric model, and it is
essentially a module/subroutine within the `Common Community Physics Package
(CCPP) <https://dtcenter.org/community-code/common-community-physics-package-ccpp>`__
repository. The UFS Land DA currently only works with snow data. Thus,
this version of the User's Guide focuses primarily on this process.

Code Repositories and Directory Structure
==============================================

The public server directory RELEASE/ in which this User’s Guide resides
contains directories:

https://github.com/NOAA-PSL/land-DA_update

https://github.com/NOAA-PSL/land-IMS_proc

https://github.com/NOAA-PSL/land-apply_jedi_incr

https://github.com/NOAA-PSL/land-vector2tile

https://github.com/barlage/ufs-land-driver

https://github.com/NCAR/ccpp-physics

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
