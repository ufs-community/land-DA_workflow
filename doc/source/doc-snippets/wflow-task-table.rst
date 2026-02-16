Each Land DA experiment includes multiple tasks that must be run in order to satisfy the dependencies of later tasks. These tasks are housed in the :term:`J-job <j-jobs>` scripts contained in the ``jobs`` directory. 

.. list-table:: *J-job Tasks in the Land DA Workflow*
   :widths: 10 50 10 15
   :header-rows: 1

   * - J-job Task
     - Description
     - Application
     - Executables
   * - PREP_DATA
     - Retrieves or creates the observation data files or the :term:`DATM` forcing data files
     - LND/ATML
     - 
   * - FCST_IC 
     - Generates initial conditions (IC) files for the ATML coldstart configuration only
     - ATML (coldstart)
     - **chgres_cube** from UFS_UTILS
   * - JCB
     - Generates :term:`JEDI` configuration YAML file
     - LND/ATML
     - 
   * - PRE_ANAL
     - Transfers the snow depth or soil moisture data from the restart files to the surface data files
     - LND
     - **tile2tile_converter.exe**
   * - ANALYSIS
     - Runs JEDI and adds the increment to the surface data files
     - LND/ATML
     - **fv3jedi_letkf.x** / **fv3jedi_var.x** & **apply_incr.exe**
   * - POST_ANAL
     - Transfers the JEDI snow depth or soil moisture result from the surface data files to the restart files
     - LND/ATML
     - **tile2tile_converter.exe**
   * - FORECAST
     - Runs the forecast model
     - LND/ATML
     - **ufs_model**
   * - PLOT_STATS
     - Plots the results of the ANALYSIS and FORECAST tasks
     - LND/ATML
     - 
