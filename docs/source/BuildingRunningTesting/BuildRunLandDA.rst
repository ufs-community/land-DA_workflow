.. _BuildRunLandDA:

************************************
Land DA Workflow (Hera & Orion)
************************************

This chapter provides instructions for building and running a basic Land DA case for the Unified Forecast System (:term:`UFS`) Land DA System. This out-of-the-box Land DA case builds a weather forecast for January 1, 2016 at 18z to January 3, 2016 at 18z. 

.. attention::
   
   These steps are designed for use on :ref:`Level 1 <LevelsOfSupport>` systems (i.e., Hera and Orion) and may require significant changes on other systems. It is recommended that users on other systems run the containerized version of Land DA. Users may reference :numref:`Chapter %s: Containerized Land DA Workflow <Container>` for instructions. 

Create a Working Directory
*****************************

Create a directory for the Land DA experiment (``$LANDDAROOT``):

.. code-block:: console

   mkdir /path/to/landda
   cd /path/to/landda
   export LANDDAROOT=`pwd`

where ``/path/to/landda`` is the path to the directory where the user plans to run Land DA experiments. 

.. _GetData:

Get Data
***********

:numref:`Table %s <Level1Data>` shows the locations of pre-staged data on NOAA :term:`RDHPCS` (i.e., Hera and Orion). 
   
.. _Level1Data:

.. table:: Level 1 RDHPCS Data

   +-----------+--------------------------------------------------+
   | Platform  | Data Location                                    |
   +===========+==================================================+
   | Hera      | /scratch1/NCEPDEV/nems/role.epic/landda/inputs   |
   +-----------+--------------------------------------------------+
   | Orion     | /work/noaa/epic-ps/role-epic-ps/landda/inputs    |
   +-----------+--------------------------------------------------+
   | Jet       | /mnt/lfs4/HFIP/hfv3gfs/role.epic/landda/inputs   |
   +-----------+--------------------------------------------------+
   | Cheyenne  | /glade/work/epicufsrt/contrib/landda/inputs      |
   +-----------+--------------------------------------------------+

Users can either set the ``LANDDA_INPUTS`` environment variable to the location of their system's pre-staged data or use a soft link to the data. For example, on Hera, users may set: 

.. code-block:: console

   export LANDDA_INPUTS=/scratch1/NCEPDEV/nems/role.epic/landda/inputs

Alternatively, users can add a soft link to the data. For example, on Orion:

.. code-block:: console

   cd $LANDDAROOT
   ln -s /work/noaa/epic-ps/role-epic-ps/landda/inputs .

Users who have difficulty accessing the data on Hera or Orion may download it according to the instructions in :numref:`Section %s <GetDataC>`. Users with access to data for additional experiments may use the same process described above to point or link to that data by modifying the path to the data appropriately. 

Users who are not using Land DA on Hera or Orion should view :numref:`Chapter %s <Container>` for instructions on running the containerized version of Land DA. :numref:`Section %s <GetDataC>` explains options for downloading the sample data onto their system. 

Get Code
***********

Clone the Land DA repository.

.. code-block:: console

   git clone -b develop --recursive https://github.com/ufs-community/land-DA_workflow.git

Build the Land DA System
***************************

#. Navigate to the workflow directory, and source the modulefiles.

   .. code-block:: console

      cd $LANDDAROOT/land-DA_workflow
      module use modulefiles
      module load landda_<machine>.intel
   
   where ``<machine>`` is either ``hera`` or ``orion``. 

#. Create and navigate to a ``build`` directory.

   .. code-block:: console

      mkdir build
      cd build

#. Build the Land DA System.

   .. code-block:: console

      ecbuild ..
      make -j 8

   If the code successfully compiles, the console output should end with:
   
   .. code-block:: console

      [100%] Completed 'ufs-weather-model'
      [100%] Built target ufs-weather-model
   
   Additionally, the ``build`` directory will contain several files and a ``bin`` subdirectory with three executables: 

      * ``apply_incr.exe``
      * ``ufsLandDriver.exe``
      * ``vector2tile_converter.exe``

Configure the Experiment
***************************

#. Navigate back to the ``land-DA_workflow`` directory and check that the account/partition is correct in ``submit_cycle.sh``. 

   .. code-block:: console

      cd ..
      vi submit_cycle.sh

   If necessary, modify lines 3 and 4 to include the correct account and queue (qos) for the system. It may also be necessary to add the following line to the script to specify the partition: 

   .. code-block:: console

      #SBATCH --partition=my_partition
   
   where ``my_partition`` is the name of the partition on the user's system. 


#. Configure other elements of the experiment if desired. The ``develop`` branch includes four scripts with default experiment settings: 

   * ``settings_DA_cycle_gdas`` for running the Jan. 1-3, 2016 sample case. 
   * ``settings_DA_cycle_era5`` for running a Jan. 1-3, 2020 sample case.
   * ``settings_DA_cycle_gdas_restart`` for running the Jan. 3-4, 2016 sample case. 
   * ``settings_DA_cycle_era5_restart`` for running a Jan. 3-4, 2020 sample case.

   These files contain reasonable default values for running a Land DA experiment. Users who wish to run a more complex experiment may change the values in these files and the files they reference using information in Chapters :numref:`%s <Model>` & :numref:`%s <DASystem>`. 

   .. note::

      The ``*restart`` settings files will only work after an experiment with the corresponding non-restart settings file has been run. These settings files are designed to use the restart files created by the first experiment cycle to pick up where it left off. For example, ``settings_DA_cycle_gdas`` runs from 2016-01-01 at 18z to 2016-01-03 at 18z. The ``settings_DA_cycle_gdas_restart`` will run from 2016-01-03 at 18z to 2016-01-04 at 18z.

Run an Experiment
********************

The Land DA System uses a script-based workflow that is launched using the ``do_submit_cycle.sh`` script. This script requires an input file that details all the specifics of a given experiment.

.. code-block:: console

   ./do_submit_cycle.sh settings_DA_cycle_gdas
      
The system will output a message such as ``Submitted batch job ########``, indicating that the job was successfully submitted. If all goes well, two full cycles will run with data assimilation (DA) and a forecast. 

.. _VerifySuccess:

Check Progress
*****************

Verify that the experiment ran successfully:
   
To check on the job status, users on a system with a Slurm job scheduler may run: 

.. code-block:: console

   squeue -u $USER

To view progress, users can open the ``log*`` and ``err*`` files once they have been generated:

.. code-block:: console

   tail -f log* err*

The ``log*`` file for a successful experiment will end with an exit code of ``0:0`` and a message like:

.. code-block:: console

   Job 42442720 (not serial) finished for user User.Name in partition hera with exit code 0:0
   
The ``err*`` file for a successful experiment will end with something similar to:

.. code-block:: console

   + THISDATE=2016010318
   + date_count=2
   + '[' 2 -lt 2 ']'
   + '[' 2016010318 -lt 2016010318 ']'

Users will need to hit ``Ctrl+C`` to exit the files. 

.. attention::

   If the log file contains a NetCDF error (e.g., ``ModuleNotFoundError: No module named 'netCDF4'``), run:
      
   .. code-block:: console
         
      python -m pip install netCDF4
      
   Then, resubmit the job (``sbatch submit_cycle.sh``).

Next, check for the background and analysis files in the ``cycle_land`` directory.

.. code-block:: console

   ls -l ../cycle_land/DA_GHCN_test/mem000/restarts/vector/
