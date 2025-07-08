.. _DASystem:

*******************************************************************
Joint Effort for Data Assimilation Integration (JEDI) DA System 
*******************************************************************

This chapter describes the :term:`Data Assimilation` (DA) system for Land DA, which utilizes the UFS :ref:`WM <wm-component>` :ref:`Noah-MP <NoahMP>` component together with the ``jedi-bundle`` to enable cycled model forecasts. The data assimilation framework applies either the ``letkf-oi`` algorithm or the ``3dvar`` algorithm. The Local Ensemble Transform Kalman Filter-Optimal Interpolation (LETKF-OI) algorithm uses pseudo-ensemble error covariance; it combines the state-dependent background error derived from an ensemble forecast with the observations and their corresponding uncertainties to produce an analysis ensemble (:cite:t:`HuntEtAl2007`, 2007). The 3-D Variational (`3D-Var <https://www.ecmwf.int/sites/default/files/elibrary/2003/76079-variational-data-assimiltion-theory-and-overview_0.pdf>`_) DA algorithm attempts to find the analysis that best represents the true state of the atmosphere by minimizing a cost function given a particular background (previous forecast) and observations. 

JEDI Overview
****************

.. attention::

   Users are encouraged to visit the :jedi:`JEDI Documentation <inside/jedi-components/index.html>`. Much of the information in this chapter is drawn directly from there with modifications to clarify JEDI's use specifically in the context of the Land DA System. 

The Joint Effort for Data assimilation Integration (:term:`JEDI`) is a unified and versatile :term:`data assimilation` (DA) system for Earth system prediction that can be run on a variety of platforms. JEDI is developed by the Joint Center for Satellite Data Assimilation (`JCSDA <https://www.jcsda.org/>`_) and partner agencies, including NOAA. It includes several components: 
   
   * The Object-Oriented Prediction System (:jedi:`OOPS <inside/jedi-components/oops/index.html>`) for the data assimilation algorithm 
   * The Interface for Observation Data Access (:jedi:`IODA <inside/jedi-components/ioda/index.html>`) for the observation formatting and processing
   * The Unified Forward Operator (:jedi:`UFO <inside/jedi-components/ufo/index.html>`) for comparing model forecasts and observations 
   * The System Agnostic Background Error Representation (:jedi:`SABER <inside/jedi-components/saber/index.html>`) for computing and manipulating the background error covariance matrix
   * The VAriable DErivation Repository (:jedi:`VADER <inside/jedi-components/vader/index.html>`) for producing new variables from known variables

.. _jedi-config-and-params:

JEDI Configuration Files & Parameters
****************************************

The Land DA System uses the JEDI Configuration Builder (:ref:`JCB <jcb-component>`) along with parameters defined in the ``land_analysis.yaml`` file to interface with the JEDI DA system. As described in :numref:`Section %s <ConfigWorkflow>`, the Land DA workflow generates a ``land_analysis.yaml`` file that contains all settings required for an experiment — user-selected settings from ``config.yaml``, default values, and machine-dependent settings. 

When the experiment is generated, the first :ref:`workflow tasks <wflow-overview>` to run are: 

   * ``jcb`` 
   * ``prep_data``
   * ``pre_anal`` (:term:`LND`) or ``fcst_ic`` (:term:`ATML`) (not required for every experiment)

The ``jcb`` task generates :term:`JEDI` configuration YAML files using JCB and information provided in the ``land_analysis.xml`` file (e.g., DA algorithm, cycle dates). The template file `jcb-base_snow.yaml.j2 <https://github.com/ufs-community/land-DA_workflow/blob/develop/parm/jedi/jcb-base_snow.yaml.j2>`_ is filled in using information from ``land_analysis.xml`` during the ``jcb`` task. This produces the ``jcb-base_snow.yaml`` file, which points to files containing information on geometry, time window, background, driver, local ensemble DA, and/or output increment. This information is used as input to create a YAML file (``jedi_<algorithm>_snow.yaml``, where ``<algorithm>`` is ``letkf-oi`` or ``3dvar``) containing detailed algorithm-specific information. These two files (``jcb-base_snow.yaml`` and ``jedi_<algorithm>_snow.yaml``) form the basis of the DA system configuration in the Land DA System. 

.. COMMENT: Or from land_analysis.yaml? ^

.. figure:: https://raw.githubusercontent.com/wiki/ufs-community/land-DA_workflow/images/jcb.png
   :width: 50%

   Outline of the JCB Task

The ``jcb`` task stores these files in the ``ptmp/test_*/tmp/jcb.${PDY}${cyc}.${jobid}/`` directory, where ``${PDY}${cyc}`` is in YYYYMMDDHH format (see :numref:`Section %s <nco-dir-entities>`), and the ``${jobid}`` is the job ID assigned by the system. Users can also access this file via the ``tmp_dir/jcb.${PDY}${cyc}.${jobid}`` shortcut in their experiment directory. The example below shows what the complete ``jcb-base_snow.yaml`` file might look like for the 2025-01-19 00Z cycle. 

.. COMMENT: Update info about GHCN.yaml since this file no longer exists as such. 

.. code-block:: yaml

   # JCB general
   JEDI_ALGORITHM: "3dvar"
   snowdepth_vn: "snwdph"
   algorithm: 3dvar
   algorithm_path: "/home/ubuntu/land-DA_workflow/parm/jedi/jcb-algorithms"
   app_path_algorithm: "/home/ubuntu/land-DA_workflow/parm/jedi/jcb-gdas/algorithm/snow"
   app_path_model: "/home/ubuntu/land-DA_workflow/parm/jedi/jcb-gdas/model/snow"
   app_path_observations: "/home/ubuntu/land-DA_workflow/parm/jedi/jcb-gdas/observations/snow"
   app_path_observation_chronicle: "/home/ubuntu/land-DA_workflow/parm/jedi/jcb-gdas/observation_chronicle/snow"

   # Template file name for each section (if not defined, default files in jcb-algorithms will be used)
   geometry_background_file: snow_geometry_background
   background_file: snow_background
   background_error_file: snow_background_error
   final_increment_file: snow_final_increment_fms

   # Time window
   window_begin: "2025-01-18T12:00:00Z"
   window_length: "PT24H"

   # Geometry
   snow_fv3jedi_files_path: "Data/fv3files"
   snow_layout_x: 1
   snow_layout_y: 1
   snow_npx_anl: 97
   snow_npy_anl: 97
   snow_npz_anl: 127
   snow_npx_ges: 97
   snow_npy_ges: 97
   snow_npz_ges: 127
   snow_orog_files_path: "/home/ubuntu/land-DA_workflow/fix/FV3_fix_tiled/C96"
   snow_orog_prefix: "C96"

   # Final/minimization
   analysis_variables: [totalSnowDepth]
   final_diagnostics_departures: anlmob
   snow_final_inc_file_path: "./"
   minimizer: DRPCG
   number_of_outer_loops: 1

   # Local Ensemble DA
   local_ensemble_da_solver: "3DVAR"
   inflation_rtps: "0.0"
   inflation_rtpp: "0.0"
   inflation_mult: "1.0"

   # Driver
   driver_do_test_prints: False
   driver_update_obs_config_with_geometry_info: False
   driver_save_posterior_mean: False
   driver_save_posterior_ensemble: False
   driver_save_posterior_mean_increment: True
   driver_do_posterior_observer: False

   # Background
   snow_background_path: "bkg"
   snow_background_time_fv3: "20250119.000000"
   snow_background_time_iso: "2025-01-19T00:00:00Z"
   snow_increment_time_fv3: "20250119.000000"
   snow_increment_time_iso: "2025-01-19T00:00:00Z"

   # Background error
   snow_bump_data_directory: "berror"

   # Observation
   observations:
   - ims_snow
   - sfcsno
   #- snocvr_snow

   # GHCN/IMS
   snow_obsdatain_path: "obs"
   snow_obsdatain_prefix: "obs.20250119.t00z."
   snow_obsdataout_path: "diags"
   snow_obsdataout_prefix: "diag."
   snow_obsdataout_suffix: "_2025011900.nc"

The example below shows what the complete ``jedi_<algorithm>_snow.yaml`` file might look like for the 2025-01-19 00Z cycle using the ``3dvar`` option. Concretely, this file would be named ``jedi_3dvar_snow.yaml``. 

.. code-block:: yaml

   cost function:
     cost type: 3D-Var
     jb evaluation: false
     time window:
       begin: '2025-01-18T12:00:00Z'
       length: PT24H
       bound to include: begin
     geometry:
       fms initialization:
         namelist filename: Data/fv3files/fmsmpp.nml
         field table filename: Data/fv3files/field_table
       akbk: Data/fv3files/akbk.nc4
       layout:
       - 1
       - 1
       npx: 97
       npy: 97
       npz: 127
       field metadata override: Data/fv3files/fv3jedi_fieldmetadata_restart.yaml
     analysis variables:
     - totalSnowDepth
     background:
       datapath: bkg
       filetype: fms restart
       skip coupler file: true
       datetime: '2025-01-19T00:00:00Z'
       state variables:
       - snwdph
       - vtype
       - slmsk
       - sheleg
       - orog_filt
       filename_sfcd: 20250119.000000.sfc_data.nc
       filename_cplr: 20250119.000000.coupler.res
       filename_orog: C96_oro_data.nc
     background error:
       covariance model: SABER
       saber central block:
         saber block name: BUMP_NICAS
         read:
           general:
             universe length-scale: 300000.0
           drivers:
             multivariate strategy: univariate
             read global nicas: true
           nicas:
             explicit length-scales: true
             horizontal length-scale:
             - groups:
               - totalSnowDepth_shadowLevels
               value: 250000.0
             vertical length-scale:
             - groups:
               - totalSnowDepth_shadowLevels
               value: 0.0
             interpolation type:
             - groups:
               - totalSnowDepth_shadowLevels
               type: c0
             same horizontal convolution: true
           io:
             data directory: berror
             files prefix: snow_bump_nicas_250km_shadowlevels
       saber outer blocks:
       - saber block name: ShadowLevels
         fields metadata:
           totalSnowDepth:
             vert_coord: filtered_orography
         calibration:
           number of shadow levels: 50
           lowest shadow level: -450.0
           highest shadow level: 8850.0
           vertical length-scale: 2000.0
       - saber block name: BUMP_StdDev
         read:
           drivers:
             compute variance: true
           variance:
             explicit stddev: true
             stddev:
             - variables:
               - totalSnowDepth
               value: 30.0
     observations:
       obs perturbations: false
       observers:
       - obs space:
           name: ims_snow
           obsdatain:
             engine:
               type: H5File
               obsfile: obs/obs.20250119.t00z.ims_snow.tm00.nc
               missing file action: warn
           obsdataout:
             engine:
               type: H5File
               obsfile: diags/diag.ims_snow_2025011900.nc
           simulated variables:
           - totalSnowDepth
         obs operator:
           name: Identity
         obs pre filters:
         - filter: Perform Action
           filter variables:
           - name: totalSnowDepth
           action:
             name: assign error
             error parameter: 80.0
         obs prior filters:
         - filter: Domain Check
           where:
           - variable:
               name: GeoVaLs/slmsk
             minvalue: 0.5
             maxvalue: 1.5
         - filter: RejectList
           where:
           - variable:
               name: GeoVaLs/vtype
             minvalue: 14.5
             maxvalue: 15.5
         obs post filters:
         - filter: Background Check
           filter variables:
           - name: totalSnowDepth
           threshold: 3.0
           action:
             name: reject
         - filter: Gaussian Thinning
           horizontal_mesh: 40.0
         - filter: Bounds Check
           filter variables:
           - name: totalSnowDepth
           minvalue: 0.0
       - obs space:
           name: sfcsno
           obsdatain:
             engine:
               type: bufr
               obsfile: obs/obs.20250119.t00z.sfcsno.tm00.bufr_d
               mapping file: obs/bufr_sfcsno_mapping.yaml
               missing file action: warn
           obsdataout:
             engine:
               type: H5File
               obsfile: diags/diag.sfcsno_2025011900.nc
           simulated variables:
           - totalSnowDepth
         obs operator:
           name: Composite
           components:
           - name: Identity
           - name: BackgroundErrorIdentity
         linear obs operator:
           name: Identity
         obs pre filters:
         - filter: Create Diagnostic Flags
           flags:
           - name: missing_snowdepth
             initial value: false
           - name: missing_elevation
             initial value: false
           - name: temporal_thinning
             initial value: false
           - name: invalid_snowdepth
             initial value: false
           - name: invalid_elevation
             initial value: false
           - name: land_check
             initial value: false
           - name: landice_check
             initial value: false
           - name: elevation_bkgdiff
             initial value: false
           - name: rejectlist
             initial value: false
           - name: background_check
             initial value: false
           - name: buddy_check
             initial value: false
         - filter: Perform Action
           filter variables:
           - name: totalSnowDepth
           action:
             name: assign error
             error parameter: 40.0
         - filter: Variable Assignment
           assignments:
           - name: GrossErrorProbability/totalSnowDepth
             type: float
             value: 0.02
           - name: BkgError/totalSnowDepth_background_error
             type: float
             value: 30.0
         - filter: Domain Check
           where:
           - variable:
               name: ObsValue/totalSnowDepth
             value: is_valid
           actions:
           - name: set
             flag: missing_snowdepth
             ignore: rejected observations
           - name: reject
         - filter: Domain Check
           where:
           - variable:
               name: MetaData/stationElevation
             value: is_valid
           actions:
           - name: set
             flag: missing_elevation
             ignore: rejected observations
           - name: reject
         - filter: Temporal Thinning
           min_spacing: PT24H
           seed_time: '2025-01-19T00:00:00Z'
           category_variable:
             name: MetaData/stationIdentification
           actions:
           - name: set
             flag: temporal_thinning
             ignore: rejected observations
           - name: reject
         obs prior filters:
         - filter: Bounds Check
           filter variables:
           - name: totalSnowDepth
           minvalue: 0.0
           maxvalue: 20000.0
           actions:
           - name: set
             flag: invalid_snowdepth
             ignore: rejected observations
           - name: reject
         - filter: Domain Check
           where:
           - variable:
               name: GeoVaLs/slmsk
             minvalue: 0.5
             maxvalue: 1.5
           actions:
           - name: set
             flag: land_check
             ignore: rejected observations
           - name: reject
         - filter: Domain Check
           where:
           - variable:
               name: MetaData/stationElevation
             minvalue: -200.0
             maxvalue: 9900.0
           actions:
           - name: set
             flag: invalid_elevation
             ignore: rejected observations
           - name: reject
         - filter: RejectList
           where:
           - variable:
               name: GeoVaLs/vtype
             minvalue: 14.5
             maxvalue: 15.5
           actions:
           - name: set
             flag: landice_check
             ignore: rejected observations
           - name: reject
         - filter: Difference Check
           reference: MetaData/stationElevation
           value: GeoVaLs/filtered_orography
           threshold: 200.0
           actions:
           - name: set
             flag: elevation_bkgdiff
             ignore: rejected observations
           - name: reject
         - filter: BlackList
           where:
           - variable:
               name: MetaData/stationIdentification
             is_in:
             - 71621
             - 10863
             - 16179
             - 40550
             - 40580
             - 40582
             - 40587
             - 40592
             - 47005
             - 47008
             - 47014
             - 47016
             - 47020
             - 47022
             - 47025
             - 47028
             - 47031
             - 47035
             - 47037
             - 47039
             - 47041
             - 47046
             - 47050
             - 47052
             - 47055
             - 47058
             - 47060
             - 47061
             - 47065
             - 47067
             - 47068
             - 47069
             - 47070
             - 47069
             - 47070
             - 47075
             - 47090
             - 48698
             - 48830
             - 65250
             - 47095
             - 47098
             - 47101
             - 47102
           actions:
           - name: set
             flag: rejectlist
             ignore: rejected observations
           - name: reject
         obs post filters:
         - filter: Background Check
           filter variables:
           - name: totalSnowDepth
           threshold: 6.25
           actions:
           - name: set
             flag: background_check
             ignore: rejected observations
           - name: reject
         - filter: Met Office Buddy Check
           filter variables:
           - name: totalSnowDepth
             rejection_threshold: 0.5
             traced_boxes:
               min_latitude: -90
               max_latitude: 90
               min_longitude: -180
               max_longitude: 180
             search_radius: 150
             station_id_variable:
               name: MetaData/stationIdentification
             num_zonal_bands: 24
             sort_by_pressure: false
             max_total_num_buddies: 15
             max_num_buddies_from_single_band: 10
             max_num_buddies_with_same_station_id: 5
             use_legacy_buddy_collector: false
             horizontal_correlation_scale:
               '-90': 150
               '90': 150
             temporal_correlation_scale: PT6H
             damping_factor_1: 1.0
             damping_factor_2: 1.0
             background_error_group: BkgError
           actions:
           - name: set
             flag: buddy_check
             ignore: rejected observations
           - name: reject
   variational:
     minimizer:
       algorithm: DRPCG
     iterations:
     - ninner: 50
       gradient norm reduction: 1e-10
       test: true
       geometry:
         fms initialization:
           namelist filename: Data/fv3files/fmsmpp.nml
           field table filename: Data/fv3files/field_table
         akbk: Data/fv3files/akbk.nc4
         layout:
         - 1
         - 1
         npx: 97
         npy: 97
         npz: 127
         field metadata override: Data/fv3files/fv3jedi_fieldmetadata_restart.yaml
         time invariant fields:
           state fields:
             datetime: '2025-01-19T00:00:00Z'
             filetype: fms restart
             skip coupler file: true
             state variables:
             - orog_filt
             datapath: /home/ubuntu/land-DA_workflow/fix/FV3_fix_tiled/C96/
             filename_orog: C96_oro_data.nc
       diagnostics:
         departures: bkgmob
   final:
     diagnostics:
       departures: anlmob
     increment:
       output:
         state component:
           datapath: ./anl
           prefix: snowinc
           filetype: fms restart
           filename_sfcd: 20250119.000000.sfc_data.nc
           filename_cplr: 20250119.000000.coupler.res
           state variables:
           - snwdph
           - vtype
           - slmsk
       geometry:
         fms initialization:
           namelist filename: Data/fv3files/fmsmpp.nml
           field table filename: Data/fv3files/field_table
         akbk: Data/fv3files/akbk.nc4
         layout:
         - 1
         - 1
         npx: 97
         npy: 97
         npz: 127
         field metadata override: Data/fv3files/fv3jedi_fieldmetadata_restart.yaml
   final j evaluation: false

Variables in the JCB YAML Files: 
===================================

The JEDI system expects YAML blocks containing information such as geometry, time window, background, driver, local ensemble DA, output increment, and/or observations. Since these can be implemented differently for different algorithms and observation types, the ``jcb`` output YAML files frequently contain distinct parameters and variable names depending on the use case. This section of the User's Guide focuses on assisting users with understanding and customizing these JEDI configuration items in order to run Land DA experiments. Users may also reference the :jedi:`JEDI Documentation <using/building_and_running/config_content.html>` for additional information. 

Geometry
----------

The :jedi:`geometry <using/building_and_running/config_content.html#geometry>` section is used in JEDI configuration files "to define the model grid (both horizontal and vertical) and its parallelization across compute nodes." Most geometry definitions in this section are borrowed from the FV3-JEDI :jedi:`Geometry <inside/jedi-components/fv3-jedi/classes.html#geometry>`, :jedi:`FieldMetadata <inside/jedi-components/fv3-jedi/classes.html#fieldmetadata>`, and :jedi:`State/Increment/Field <inside/jedi-components/fv3-jedi/classes.html#state-increment-fields>` documentation. Note that for variational (e.g., 3D-Var data assimilation), the ``geometry:`` section appears in :jedi:`multiple places <inside/jedi-components/mpas-jedi/classes.html#nml-file-and-streams-file>` --- under ``cost function:`` and within each of the ``iterations:`` vector members under ``variational:``.

   ``fms initialization:``
      This section contains two parameters, ``namelist filename`` and ``field table filename``, which are required for :term:`FMS` initialization. 

      ``namelist filename`` (Default: Data/fv3files/fmsmpp.nml)
         Specifies the path to the namelist file used to initialize the FMS library.

      ``field table filename`` (Default: Data/fv3files/field_table)
         Specifies the path to the field table file, which provides a list of tracers that the model will use.

   ``akbk`` (Default: Data/fv3files/akbk.nc4)
      Specifies the path to a file containing the coefficients that define the hybrid sigma-pressure vertical coordinates used in FV3. 

   ``npx`` (Default: 97)
      Specifies the number of grid points in the east-west direction.

   ``npy`` (Default: 97)
      Specifies the number of grid points in the north-south direction.

   ``npz`` (Default: 64)
      Specifies the number of vertical layers.

   ``field metadata override:`` (Default: Data/fv3files/fv3jedi_fieldmetadata_restart.yaml)
      Specifies the path to field metadata file, which is a YAML file overwriting some default fields that the system will be able to allocate. See :jedi:`FieldMetadata documentation <inside/jedi-components/fv3-jedi/classes.html#fieldmetadata>`.

   ``time invariant fields:``
      This YAML section contains state fields and derived fields. See :jedi:`State/Increment/Field documentation <inside/jedi-components/fv3-jedi/classes.html#state-increment-fields>`.

      ``state fields:``
         Used to define multiple unit tests for the model state, including file IO, interpolation, variable changes, increments, and computation of the background error covariance matrix. This parameter contains several subparameters listed below.

         ``datetime`` (Default: XXYYYP-XXMP-XXDPTXXHP:00:00Z) 2025-01-19T00:00:00Z
            Specifies the time in YYYY-MM-DDTHH:00:00Z format, where YYYY is a 4-digit year, MM is a valid 2-digit month, DD is a valid 2-digit day, and HH is a valid 2-digit hour. 

         ``filetype`` (Default: fms restart)
            Specifies the type of file. Valid values include: ``fms restart``

         ``skip coupler file`` (Default: true)
            Specifies whether to enable skipping coupler file. Valid values are: ``true`` | ``false``

         ``state variables``
            Specifies the list of state variables. Valid values may include: ``[orog_filt, snwdph, vtype, slmsk, sheleg]``
           
         ``datapath`` (Default: $LANDDAROOT/land-DA_workflow/fix/FV3_fix_tiled/C96)
            Specifies the path for state variables data.

         ``filename_orog`` (Default: C96_oro_data.nc)
            Specifies the name of orographic data file.

Window begin, Window length
-----------------------------

These two items define the assimilation window for many applications, including Land DA. See :jedi:`JEDI time window documentation <using/building_and_running/config_content.html#time-window>`.

``time window:`` 
   Contains information related to the start, end, and length of the experiment. 

   ``begin:`` (Default: XXYYYP-XXMP-XXDPTXXHP:00:00Z)
      Specifies the beginning time window in ISO-8601 format. The format is YYYY-MM-DDTHH:00:00Z, where YYYY is a 4-digit year, MM is a valid 2-digit month, DD is a valid 2-digit day, and HH is a valid 2-digit hour.

   ``length:`` (Default: PT24H)
      Specifies the time window length in ISO-8601 format. The form is PTXXH, where XX is a 1- or 2-digit hour. For example: ``PT6H``
   
   ``bound to include:``
      Specifies which assimilation window bound is inclusive. Valid values: ``begin`` | ``end``

Observations
--------------

The ``observations:`` field describes one or more types of observations, each of which is a multi-level YAML/JSON object in and of itself. Each of these observation types is read into JEDI as an ``eckit::Configuration`` object (see :jedi:`JEDI Observations Documentation <using/building_and_running/config_content.html#observations>` for more details).

``obs space:``
^^^^^^^^^^^^^^^^

The ``obs space:`` section of the YAML comes under the ``observations.observers:`` section and describes the configuration of the observation data for a single observation type. One experiment can use multiple types of observations. For example, the ``LND.era5.3dvar.ims.warmstart.yaml`` experiment uses both ``ims_snow`` and ``sfcsno`` observation data. 

   ``name:`` 
      Specifies the name of the observation data (also called the "observation space"). Valid values: ``ims_snow`` | ``sfcsno`` | ``ghcn_snow``

   ``distribution:``
      ``name:``
         Specifies the name of the distribution. ``InefficientDistribution`` "prevents the observations from distributing to different processors between the original obs space and the auxiliary obs space, which could cause in-window observations flagged in the auxiliary obs space to be left unflagged in the original obs space." Valid values include: ``InefficientDistribution`` See :jedi:`JEDI distribution documentation <inside/jedi-components/oops/applications/localensembleda.html#note-about-obs-distributions>`.

   ``simulated variables:``
      Specifies the list of variables that need to be simulated by the observation operator. Valid values: ``[totalSnowDepth]``

   ``obsdatain:``
      This section specifies information about the observation input data. See :jedi:`JEDI File documentation <inside/conventions/files_and_components.html#files>`.

      ``engine:``
         A type of file provider (e.g., HDF5, BUFR, NetCDF). Attributes in this section provide information required for the file matching engine.  

         ``type:`` 
            Specifies the type of input observation data. Valid values: ``H5File`` | ``OBS`` | ``bufr``

         ``obsfile:`` (Default: obs/obs.YYYYMMDD.tHHz.<obs_type>.nc)
            Specifies the relative path to the input file, where ``<obs_type>`` is one of the values in ``obs space.name``. 

   ``obsdataout:``
      This section contains information about the observation output data. See :jedi:`JEDI File documentation <inside/conventions/files_and_components.html#files>`.

      ``engine:``
         A type of file provider (e.g., HDF5, BUFR, NetCDF). Attributes in this section provide information required for the file matching engine. 

         ``type:`` (Default: H5File)
            Specifies the type of output observation data. Valid values: ``H5File``

         ``obsfile:`` (Default: diags/diag.<obs_type>_YYYYMMDDHH.nc)
            Specifies the relative path to the output file, where ``<obs_type>`` is one of the values in ``obs space.name``. 

``obs operator:``
^^^^^^^^^^^^^^^^^^^

The ``obs operator:`` section describes the observation operator and its options. An observation operator is used for computing H(x).

   ``name:`` (Default: Identity)
      Specifies the name in the ``ObsOperator`` and ``LinearObsOperator`` factory, defined in the C++ code. Valid values include: ``Identity``. See :jedi:`JEDI Documentation for Observation Operators <inside/jedi-components/ufo/obsops.html#top-ufo-obsops>` for more options. 

``obs error:``
^^^^^^^^^^^^^^^^

The ``obs error:`` section explains how to calculate the observation error covariance matrix and gives instructions (required for DA applications). The key covariance model, which describes how observation error covariances are created, is frequently the first item in this section. For diagonal observation error covariances, only the diagonal option is currently supported. See more on obs error in the :jedi:`JEDI Observations documentation <using/building_and_running/config_content.html#observations>`.

   ``covariance model:``
      Specifies the covariance model. Valid values include: ``diagonal``

``obs localizations:``
^^^^^^^^^^^^^^^^^^^^^^^^

``obs localizations:``
   ``localization method:``
      Specifies the observation localization method. Valid values include: ``Horizontal SOAR`` | ``Vertical Brasnett``

      +--------------------+--------------------------------------------------+
      | Value              | Description                                      |
      +====================+==================================================+
      | Horizontal SOAR    | Second Order Auto-Regressive localization in     |
      |                    | the horizontal direction.                        |
      +--------------------+--------------------------------------------------+
      | Vertical Brasnett  | Vertical component of the localization scheme    |
      |                    | defined in :cite:t:`Brasnett1999` (1999)         |
      |                    | and used in the snow DA.                         |
      +--------------------+--------------------------------------------------+

   ``lengthscale:``
      Radius of influence (i.e., maximum distance of observations from the location being updated) in meters. Format is e-notation. For example: ``250e3``
      
   ``soar horizontal decay:``
      Decay scale of SOAR localization function. Recommended value: ``0.000021``. Users may adjust based on need/preference. 

   ``max nobs:``
      Maximum number of observations used to update each location. 
   
   ``vertical lengthscale:`` (Default: 700)
      Maximum vertical localization distance in meters from given coordinate.

``obs filters:``/ ``obs [pre|prior|post] filters:``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Observation filters define which Quality Control (QC) filters to use. They have access to observation values and metadata, model values at observation locations, simulated observation value, and their own private data. See :jedi:`Observation Filters <inside/jedi-components/ufo/qcfilters/introduction.html#observation-filters>` in the JEDI Documentation for more detail. The ``obs filters:`` section contains the following fields:

   ``filter:``
      Specifies a QC filter and its parameters. Valid values include: ``Bounds Check`` | ``Background Check`` | ``Create Diagnostic Flags`` | ``Domain Check`` | ``RejectList`` | ``Perform Action`` | ``Variable Assignment`` | ``Temporal Thinning`` | ``Difference Check`` | ``BlackList`` | ``Met Office Buddy Check``. The descriptions below are pulled directly from JEDI's documentation on :jedi:`Generic QC Filters <inside/jedi-components/ufo/qcfilters/GenericQC.html>`; users should view JEDI's documentation for detailed descriptions and information on filter parameters. The documentation also includes additional filter options. 

      .. list-table:: JEDI QC Filters
         :header-rows: 1

         * - Filter Name
           - Description
         * - :jedi:`Bounds Check <inside/jedi-components/ufo/qcfilters/GenericQC.html#bounds-check-filter>`
           - Rejects observations whose values lie outside specified limits 
         * - :jedi:`Background Check <inside/jedi-components/ufo/qcfilters/GenericQC.html#background-check-filter>` 
           - Checks for bias-corrected distance between the observation value and model-simulated value (*y* - *H(x)*) and rejects observations where the absolute difference is larger than the ``absolute threshold`` or the :math:`threshold * observation error` or the :math:`threshold * background error`. 
         * - :jedi:`Domain Check <inside/jedi-components/ufo/qcfilters/GenericQC.html#domain-check-filter>`
           - Retains all observations selected by the ``where`` statement and rejects all others. 
         * - :jedi:`BlackList / RejectList <inside/jedi-components/ufo/qcfilters/GenericQC.html#blacklist-filter>`
           - Rejects all observations selected by the :jedi:`where <inside/jedi-components/ufo/qcfilters/FilterOptions.html#where-statement>` statement. The status of all others remains the same. Opposite of Domain Check filter.
         * - :jedi:`Perform Action <inside/jedi-components/ufo/qcfilters/GenericQC.html#perform-action-filter>`
           - Performs the action specified in the action parameter on observations selected by the ``where`` statement.
         * - :jedi:`Temporal Thinning <inside/jedi-components/ufo/qcfilters/GenericQC.html#temporal-thinning-filter>`
           - Thins observations so that the retained ones are sufficiently separated in time
         * - :jedi:`Difference Check <inside/jedi-components/ufo/qcfilters/GenericQC.html#difference-check-filter>`
           - Compares the difference between a reference variable and a second variable and assigns a QC flag if the difference is outside of a prescribed range.
         * - :jedi:`Met Office Buddy Check <inside/jedi-components/ufo/qcfilters/GenericQC.html#met-office-buddy-check-filter>`
           - Cross-checks observations taken at nearby locations against each other, updates their gross error probabilities (PGEs), and rejects observations whose PGE exceeds a threshold specified in the filter parameters. 
         * - :jedi:`Variable Assignment <inside/jedi-components/ufo/qcfilters/GenericQC.html#variable-assignment-filter>`
           - Assigns specified values to specified variables at locations selected by the ``where`` statement or at all locations if the *where* keyword is not present.
         * - :jedi:`Create Diagnostic Flags <inside/jedi-components/ufo/qcfilters/GenericQC.html#create-diagnostic-flags-filter>`
           - A "processing step" that makes it possible to define new diagnostic flags and to reinitialize existing ones.

   ``filter variables:``
      Limit the action of a QC filter to a subset of variables or to specific channels. 

      ``name:``
         Name of the filter variable. Users may indicate additional filter variables using the ``name:`` field on consecutive lines (see code snippet below). Valid values include: ``totalSnowDepth``

         .. code-block:: yaml

            filter variables:
            - name: variable_1
            - name: variable_2

   ``minvalue:``
      Minimum value for variables in the filter. 

   ``maxvalue:``
      Maximum value for variables in the filter. 

   ``threshold:``
      This variable may function differently depending on the filter it is used in. In the :jedi:`Background Check Filter <inside/jedi-components/ufo/qcfilters/GenericQC.html#background-check-filter>`, an observation is rejected when the difference between the observation value (*y*) and model simulated value (*H(x)*) is larger than the :math:`threshold * observation error`. 

   ``action:``
      Indicates which action to take once an observation has been flagged by a filter. See :jedi:`Filter Actions <inside/jedi-components/ufo/qcfilters/FilterOptions.html#filter-actions>` in the JEDI documentation for a full explanation and list of valid values. 

      ``name:``
         The name of the desired action. Valid values include: ``accept`` | ``reject``

   ``where:``
      By default, filters are applied to all filter variables listed. The ``where`` keyword applies a filter only to observations meeting certain conditions. See the :jedi:`Where Statement <inside/jedi-components/ufo/qcfilters/FilterOptions.html#where-statement>` section of the JEDI Documentation for a complete description of valid ``where`` conditions. 
               
      ``variable:``
         A list of variables to check using the ``where`` statement. 

         ``name:``
            Name of a variable to check using the ``where`` statement. Multiple variable names may be listed under ``variable``. The conditions in the where statement will be applied to all of them. For example: 

            .. code-block:: yaml

               filter: Domain Check # land only
                 where:
                 - variable:
                     name: variable_1
                     name: variable_2
                   minvalue: 0.5
                   maxvalue: 1.5

      ``minvalue:``
         Minimum value for variables in the ``where`` statement.

      ``maxvalue:``
         Maximum value for variables in the ``where`` statement.

Main 3D-Var Parameters
-------------------------

The :jedi:`main components for running a 3D-Var data assimilation experiment <inside/jedi-components/oops/applications/variational.html#variational-application-yaml-structure>` are ``cost function:``, ``variational:``, and ``final:``. 

``cost function:``
^^^^^^^^^^^^^^^^^^^^

The ``cost function:`` block includes information on ``cost type:`` and ``jb evaluation:``. The Land DA System only uses the 3D-Var cost type, but :jedi:`other variational options are available in JEDI <inside/jedi-components/oops/applications/variational.html#supported-cost-functions>` and could be added to Land DA if desired. ``jb evaluation:`` determines whether (or not) to evaluate the background cost function (:math:`J_b`). Additional subsections such as geometry, time window, etc. may be included within the cost function block. 

.. code-block:: yaml

   cost function:
     cost type: 3D-Var
     jb evaluation: false
     time window: ...
     geometry: ...
     analysis variables: ...
     background: ...
     background error: ...
     observations: ...

``variational:``
^^^^^^^^^^^^^^^^^^

The ``variational:`` block contains information on :jedi:`minimizers <inside/jedi-components/oops/applications/variational.html#supported-minimizers>` and ``iterations``. Minimizers tell OOPS which algorithm to use to minimize the cost function. The ``iterations`` section defines certain parameters for the outer loop in the algorithm. 

.. code-block:: yaml

   variational:
     minimizer:
       algorithm: DRPCG
     iterations:
     - ninner: 50
       gradient norm reduction: 1e-10
       test: true


``final:``
^^^^^^^^^^^^

The ``final:`` block is optional but used frequently to configure the output diagnostics from the variational analysis. These could be observation space diagnostics or interpolated analysis/increment fields. 

.. code-block:: yaml

   final:
     diagnostics:
       departures: anlmob
     increment:
       output:
         state component:
           datapath: ./anl
           prefix: snowinc
           filetype: fms restart
           filename_sfcd: 20250119.000000.sfc_data.nc
           filename_cplr: 20250119.000000.coupler.res
           state variables:
           - snwdph
           - vtype
           - slmsk
       geometry:
         ...
   final j evaluation: false

``diagnostics.departures:`` (Default: ``anlmob``)
   Saves the difference between H(analysis) and observations in the output file. 

``increment.output:`` 
   This field indicates information about the increment output file(s). In the example above, the Land DA increment file will be located in the temp directory for the analysis task under the ``anl`` subdirectory (e.g., ``tmp_dir/analysis.${cycle_date}.${jobid}``). Each file will be prefixed with the name ``snowinc``, followed by the cycle date/time and type of file (i.e., ``coupler.res`` or ``sfc_data.{tile#}.nc``). For example, ``snowinc.20250119.000000.coupler.res`` or ``snowinc.20250119.000000.sfc_data.tile4.nc`` 

The ``increment`` field also includes a ``geometry`` block similar to other sections of the YAML. 

After the ``final`` block, there is a one-line ``final j evaluation:`` "block" indicating whether to evaluate J (the cost function). In Land DA, this field is set to false by default. 

Background Error (for ``3dvar``)
----------------------------------

The ``background error:`` block provides information and specifications for computing the :jedi:`background error covariance matrix <using/building_and_running/config_content.html#background-error>`, or **B** matrix. The first item in this section is usually the covariance model, which identifies the method for computing the B matrix. Typically, the JEDI :jedi:`SABER <inside/jedi-components/saber/index.html#saber>` package is used for this purpose. The JEDI documentation provides an :jedi:`Introduction to SABER Error Covariance Model <inside/jedi-components/saber/SABER_intro.html>` and :jedi:`additional detailed information on the SABER blocks <inside/jedi-components/saber/BUMP_saber_blocks.html>`. 

Background (for ``letkf-oi``)
------------------------------
The ``background:`` section includes information on the forecast members generated by the previous cycle, which form the background for the current cycle. 

   ``datapath:`` (Default: bkg)
      Specifies the path for state variable data. Valid values: ``mem_pos/`` | ``mem_neg/``. (With default experiment values, the full path will be ``ptmp/test_*/tmp/analysis.${PDY}${cyc}.${jobid}``.)

   ``filetype:`` (Default: fms restart)
      Specifies the type of file. Valid values include: ``fms restart``

   ``skip coupler file`` (Default: true)
         Specifies whether to enable skipping coupler file. Valid values are: ``true`` | ``false``

   ``datetime:`` (Default: XXYYYY-XXMM-XXDDTXXHH:00:00Z)
      Specifies the date and time. The format is YYYY-MM-DDTHH:00:00Z, where YYYY is a 4-digit year, MM is a valid 2-digit month, DD is a valid 2-digit day, and HH is a valid 2-digit hour. 

      .. COMMENT: Date & time of the background forecast? 

   ``state variables:``
      Specifies a list of state variables. Valid values: ``[snwdph,vtype,slmsk,sheleg,orogfilt]``

   
   ``filename_sfcd:`` (Default: XXYYYYXXMMXXDD.XXHH0000.sfc_data.nc)
      Specifies the name of the surface data file. This usually takes the form ``YYYYMMDD.HHmmss.sfc_data.nc``, where YYYY is a 4-digit year, MM is a valid 2-digit month, DD is a valid 2-digit day, and HH is a valid 2-digit hour, mm is a valid 2-digit minute and ss is a valid 2-digit second. For example: ``20000103.000000.sfc_data.nc``
         
   ``filename_cplr:`` (Default: XXYYYYXXMMXXDD.XXHH0000.coupler.res)
      Specifies the name of file that contains metadata for the restart. This usually takes the form ``YYYYMMDD.HHmmss.coupler.res``, where YYYY is a 4-digit year, MM is a valid 2-digit month, DD is a valid 2-digit day, and HH is a valid 2-digit hour, mm is a valid 2-digit minute and ss is a valid 2-digit second. For example: ``20000103.000000.coupler.res``

   ``filename_orog:`` (Default: C96_oro_data.nc)
      Specifies the name of the orographic data file. 

Driver (for ``letkf-oi``)
--------------------------

The ``driver:`` section describes optional modifications to the behavior of the LocalEnsembleDA driver. For details, refer to :jedi:`Local Ensemble Data Assimilation in OOPS <inside/jedi-components/oops/applications/localensembleda.html#top-oops-localensda>` in the JEDI Documentation. Not all options are included here. 

   ``save posterior mean:`` (Default: false)
      Specifies whether to save the posterior mean. Valid values: ``true`` | ``false``
      
   ``save posterior mean increment:`` (Default: true)
      Specifies whether to save the posterior mean increment. Valid values: ``true`` | ``false``

   ``save posterior ensemble:`` (Default: false)
      Specifies whether to save the posterior ensemble. Valid values: ``true`` | ``false``

   ``run as observer only:`` (Default: false)
      Specifies whether to run as observer only. Valid values: ``true`` | ``false``

Local Ensemble DA (for ``letkf-oi``)
-------------------------------------

The ``local ensemble DA:`` section configures the local ensemble DA solver package. 

   ``solver:`` (Default: LETKF)
      Specifies the type of solver. Currently, ``LETKF`` is the only available option. See :cite:t:`HuntEtAl2007` (2007).

   ``inflation:``
      Describes ensemble :jedi:`inflation methods supported in the ensemble solver <inside/jedi-components/oops/applications/localensembleda.html#inflation-supported-in-the-ensemble-solvers>`. 

      ``rtps:`` (Default: ``0.0``)
         Relaxation to prior spread (:cite:t:`Whitaker&Hamill2012`, 2012). 

      ``rtpp:`` (Default: ``0.0``)
         Relaxation to prior perturbation (:cite:t:`ZhangEtAl2004`, 2004). 

      ``mult:`` (Default: ``1.0``)
         Parameter of multiplicative inflation.

Output Increment (for ``letkf-oi``)
------------------------------------

``output increment:`` (Default: fms restart)
   ``filetype:``
      Type of file provided for the output increment. Valid values include: ``fms restart``

   ``filename_sfcd:`` (Default: snowinc.sfc_data.nc)
      Name of the file provided for the output increment. For example: ``snowinc.sfc_data.nc``

.. _IODA:

Interface for Observation Data Access (IODA)   
***********************************************

*This section references Honeyager, R., Herbener, S., Zhang, X., Shlyaeva, A., and Trémolet, Y., 2020: Observations in the Joint Effort for Data assimilation Integration (JEDI) - UFO and IODA. JCSDA Quarterly, 66, Winter 2020.*

The Interface for Observation Data Access (IODA) is a subsystem of JEDI that can handle data processing for various models, including the Land DA System. Currently, observation data sets come in a variety of formats (e.g., netCDF, BUFR, GRIB) and may differ significantly in structure, quality, and spatiotemporal resolution/density. Such data must be pre-processed and converted into model-specific formats. This process often involves iterative, model-specific data conversion efforts and numerous cumbersome ad-hoc approaches to prepare observations. Requirements for observation files and I/O handling often result in decreased I/O and computational efficiency. IODA addresses this need to modernize observation data management and use in conjunction with the various components of the Unified Forecast System (:term:`UFS`).

IODA provides a unified, model-agnostic method of sharing observation data and exchanging modeling and data assimilation results. The IODA effort centers on three core facets: (i) in-memory data access, (ii) definition of the IODA file format, and (iii) data store creation for long-term storage of observation data and diagnostics. The combination of these foci enables optimal isolation of the scientific code from the underlying data structures and data processing software while simultaneously promoting efficient I/O during the forecasting/DA process by providing a common file format and structured data storage.

The IODA file format represents observational field variables (e.g., temperature, salinity, humidity) and locations in two-dimensional tables, where the variables are represented by columns and the locations by rows. Metadata tables are associated with each axis of these data tables, and the location metadata hold the values describing each location (e.g., latitude, longitude). Actual data values are contained in a third dimension of the IODA data table; for instance: observation values, observation error, quality control flags, and simulated observation (H(x)) values.

Since the raw observational data come in various formats, a diverse set of "IODA converters" exists to transform the raw observation data files into IODA format. While many of these Python-based IODA converters have been developed to handle marine-based observations, users can utilize the "IODA converter engine" components to develop and implement their own IODA converters to prepare arbitrary observation types for data assimilation within JEDI. 

The Land DA System includes options to use observation data in :term:`GHCN`, :term:`IMS`, and :term:`SFCSNO` format. It also includes a variety of utility scripts to convert observation data to IODA format: 

* :github:`ghcn_snod2ioda.py <blob/develop/ush/ghcn_snod2ioda.py>`
* :github:`imsfv3_scf2ioda.py <blob/develop/ush/imsfv3_scf2ioda.py>`

IODA can also read in certain :jedi:`file formats <inside/jedi-components/ioda/file-formats.html>`, such as BUFR, with a mapping file, such as the :github:`bufr_sfcsno_mapping.yaml <blob/develop/parm/jedi/bufr_sfcsno_mapping.yaml>` file available in the Land DA repository. 

Developers are in the process of adding soil moisture DA to the Land DA system. This functionality will use Soil Moisture Active Passive (:term:`SMAP`) observations and the :github:`smap_ssm2ioda.py <blob/develop/ush/smap_ssm2ioda.py>` utility script to convert observation data to IODA format. 