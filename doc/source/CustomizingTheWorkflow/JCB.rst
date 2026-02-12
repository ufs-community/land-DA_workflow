.. _JCBInfo:

==================================
JEDI Configuration Builder (JCB)
==================================

The :term:`JEDI` Configuration Builder (JCB) is a tool that facilitates the use of JEDI :term:`DA` in :term:`NWP` workflows. The JCB ecosystem currently consists of three repositories: JCB, JCB-algorithms, and JCB-gdas. :numref:`Figure %s <jcb_flow_diagram>` shows how the repositories relate to each other. The main JCB repository collects templates from the other two repositories to assemble a final YAML file that follows JEDI conventions. The JCB-algorithms repository contains subtemplates for the actual JEDI algorithms (e.g., *LETKF* or *3D-Var*). The JCB-gdas repository contains subtemplates for assimilating particular types of data (e.g., snow, marine). The YAML files that control JEDI functionality can be extremely complex, but JCB simplifies the process of creating a valid JEDI configuration file. 

.. _jcb_flow_diagram:

.. figure:: https://raw.githubusercontent.com/wiki/ufs-community/land-DA_workflow/images/JCB_flow_diagram.png
   :align: center
   :alt: JCB flow diagram

   Flow Diagram of JCB

Concretely, repositories that implement JCB interact with the main JCB code via a JCB input file. In the Land DA repository, this file is called ``jcb-base.yaml``, and it is built using the JCB template file ``parm/jedi/jcb-base_land.yaml.j2``. When users run ``parm/setup_wflow_env.py`` to set up the workflow, ``jcb-base.yaml`` is produced by rendering ``jcb-base_land.yaml.j2`` using values from the user's ``config.yaml`` file. JCB uses this ``jcb-base.yaml`` file to assemble the proper subtemplates from the JCB-algorithms and JCB-gdas repositories into the final JEDI DA workflow file. Note that JCB can generate a JEDI input configuration YAML file only when ``CUSTOM_JEDI_CONFIG_FLAG: NO`` in the configuration file.

JCB Components
================

The JCB ecosystem has three components: JCB, JCB-algorithms, and JCB-gdas. 

.. list-table:: JCB and component repositories
   :header-rows: 1

   * - Component
     - Authoritative Repository Link
     - NOAA-EPIC Fork (if applicable)
   * - JCB
     - https://github.com/NOAA-EMC/jcb
     - N/A
   * - JCB-algorithms
     - https://github.com/NOAA-EMC/jcb-algorithms
     - https://github.com/NOAA-EPIC/jcb-algorithms
   * - JCB-gdas
     - https://github.com/NOAA-EMC/jcb-gdas
     - https://github.com/NOAA-EPIC/jcb-gdas
   
.. note:: 
   The authoritative EMC JCB-gdas repository contains four categories for analysis models: *aero*, *atmosphere*, *marine*, and *snow*. However, the EPIC fork of JCB-gdas has one more category---*land*---that contains subcomponent files not only for snow analysis but also for soil-moisture analysis. 

7.1.4 Pre-processing for SOCA
================================
1. ‘gridgen’
2. ‘setcorscales’
3. ‘parameters_diffusion’

7.1.5 Observation Data: Atmosphere
========================================
1. ASCAT wind data from MetOp-B satellite
• ASCAT: microwave radar instrument that measures ocean surface wind speed and
direction
• MetOp-B: one of the EUMETSAT MetOp polar-orbiting satellites (type B)
• 12.5km or 25km wind vector cells
• Level-2 (swath) or Level-3 (gridded) format (NetCDF)
2. Microwave radiance observation from ATMS instrument on NOAA-20
• Advanced Technology Microwave Sounder (ATMS): cross-track microwave radiometer
used for temperature and moisture sounding
• NOAA-20 satellite (JPSS-1)
• One of the highest impact observing systems in global NWP
• Works day/night, all weather except heavy precipitation effects)
• Strong constraint on tropospheric and stratospheric temperature, moisture structure, and
large-scale dynamics
• ATMS has 22 channels spanning:
Radiances (brightness temperatures):
– Oxygen band (50–60 GHz): temperature sounding
– Water vapor band (183 GHz): moisture sounding
– Window channels: surface / cloud screening
3. Conventional surface pressure observations
• In-situ (non-satellite) observations of the surface pressure (station pressure)
• SYNOP (WMO land stations), METAR/ASOS/AWOS, buoys and ships
• Units: Pa
4. GNSS Radio Occultation observations from COSMIC-2 mission
• Global Navigation Satellite System Radio Occultation (GNSSRO)
• Constellation Observing System for Meteorology, Ionosphere, and Climate (COSMIC)-2
Bending angle, refractivity
• Derived profiles: temperature, pressure, water vapor
• Surface (near-surface) vertical coverage: 40–60km
• Vertical resolution: 100–200m in the troposphere
• Very high density in the tropics (±30° latitude)
• Low bias, all-weather, self-calibrating
• Excellent for upper-troposphere lower-stratosphere (UTLS), tropical temperature struc-
ture, and large-scale circulation
5. Ozone mapping and profiler suite total column ozone from Suomi-NPP
• Satellite instrument suite for measuring ozone and related trace gases
• Derived from OMPS Nadir Mapper (NM) instrument
• Global daily coverage
• Horizontal resolution: 50km (varies by processing level)
• Level-2 (swath) or Level-3 (gridded) format (NetCDF)
6. Ozone vertical profile observation from OMPS Nadir profiler on Suomi-NPP
• Vertical coverage: from 100hPa up to 1 hPa (upper troposphere to mesosphere)
• Best sensitivity in the stratosphere
• Observation errors increase rapidly near profile edges
7. AMV from ABI on GOES-16
• AMV (Atmospheric motion vectors): winds derived by tracking cloud or water-vapor
features
• ABI (Advanced Baseline Imager): main imager on GOES-R-series satellites
• GOES-16: first GOES-R satellite
• Wind types: IR cloud-top winds, water vapor (WV) winds (upper/mid-troposphere),
visible winds
• Temporal resolution: 5–15 min
• Vertical coverage: 1000–100hPa
• Spatial density: very high (thinning is essential)

7.1.6 Observation Data: Snow
===============================
1. GHCN:
• Global Historical Climatology Network (GHCN) snow data
• Configuration parameter to turn on/off this option: OBS_SNOW_GHCN
• IODA converting python script: {USHufsda}/ghcn_snod2ioda.py
• Data path: {DCOMINghcn}
• Input files:
(a) {YYYY}.csv
(b) ghcnd-stations.txt
• Output file: ghcn_snow_{PDY}{cyc}.nc
2. IMS:
• Interactive Multisensor Snow and Ice Mapping System (IMS) snow data
• Configuration parameter to turn on/off this option: OBS_SNOW_IMS
(a) IMS data converter: ‘calcfIMS.exe’
• Input files
i. Data path: {COMINgdas} (archive of GDAS result files)
ii. ims{jdate}_4km_v1.3.asc (GDAS data from COMINgdas)
iii. IMS4km_to_FV3_mapping.C{RES}_oro_data.nc
iv. sfc_data.tile#.nc
v. fims.nml (input namelist)
• Output file: IMSscf.{PDY}.C{RES}_oro_data.nc
(b) IODA converting python script: {USHufsda}/imsfv3_scf2ioda.py
• Input file: IMSscf.{PDY}.C{RES}_oro_data.nc
• Output file: obs.{PDY}.{cycle}.ims_snow.tm00.nc
3. SFCSNO:
• WMO (World Meteorological Organization)’s Global Telecommunication System (GTS)
snow data

• Configuration parameter to turn on/off this option: OBS_SNOW_SFCSNO
• Data path: {COMINgdas} (archive of GDAS result files)
• File name: obs.{PDY}.{cycle}.sfcsno.tm00.bufr_d

7.1.7 Observation: Soil Moisture SMAP
======================================

SMAP (Soil Moisture Active Pasive) soil moisture:

* Configuration parameter to turn on/off this option: OBS_SWC_SMAP
* IODA converting python script: {USHufsda}/smap_ssm2ioda.py
* Data path: {DCOMINsmap}
* Input files: SMAP_L2_SM_P_E_[time info].h5
* Output file name: smap_combined_{PDY}{cycle}.nc

Configuration parameter ‘SMAP_RAW_WINDOW_SPAN_HALF’:

Figure 7.2: SMAP data: (top left) 2025:01:17:12:56 (top right) 2025:01:17:23:36 (bottom left)
2025:01:18:00:25 (bottom right) Combined plot for 2025011800 ±5 hours
The SMAP satellite is designed to create a global map every 2–3 days. Each SMAP data
file covers a narrow and long area of 1000 km width as shown in the bottom left figure
in Figure 7.2 which is the soil moisture at 00:25am on 01/18/2025. The top right and left
figures illustrate that the soil moisture overlaps in some regions at 12:56pm and 11:36pm

on 01/17/2025. To avoid this kind of duplication and cover as wide an area as possible,
the data files between {PDY}{cyc} - {SMAP_RAW_WINDOW_SPAN_HALF} hour and
{PDY}{cyc} +{SMAP_RAW_WINDOW_SPAN_HALF} hour are combined after the raw
data files are converted into the IODA format in the ‘prep_data’ task. Its default value is ‘5’
in the configuration. This means that the 11 hour data sets are combined by default. The
bottom right figure shows a combined data for 2025011800 which contains the raw data files
between 2025011719 and 2025011805. If you want to use a single data set, you should set
the configuration parameter to ‘0’.

The Soil Moisture Active Passive Data (SMAP) raw data files can be downloaded from the
‘NSIDC’ website as follows:

1. Log in to National Snow and Ice Data Center (NSIDC):
urs.earthdata.nasa.gov
2. Click the ‘DATA > Explore Data’ tap on the top menu:
Figure 7.3: SMAP data download step 2: DATA > Explore Data
3. Select ‘Soil Moisture Active Passive Data (SMAP)’ on the list:
Figure 7.4: SMAP data download step 3: SMAP
4. Click the ‘Data’ tab on the right panel:

Figure 7.5: SMAP data download step 4: Data
5. Select ‘SMAP Enhanced L2 Radiometer half-Orbit 9km EASE-Grid Soil Moisture,
Version 6 (SPL2SMP_E)’ on the list:
Figure 7.6: SMAP data download step 5: SPL2SMP_E
6. Click ‘Get Data’ under ‘HTTPS File System’:
Figure 7.7: SMAP data download step 6: Get Data
7. Navigate the date you want to download and click the files:

Figure 7.8: SMAP data download step 7:Data date
7.1.8 Observation: Soil Moisture SMOPS
========================================
https://www.star.nesdis.noaa.gov/pub/smcd/emb/SMOPS/SMOPScdr/V2.0/


