.. _TestingLandDA:

************************************
Testing the Land DA Workflow
************************************

This chapter provides instructions for using the Land DA CTest suite. These steps are designed for use on :ref:`Level 1 <LevelsOfSupport>` systems (i.e., Hera and Orion) and may require significant changes on other systems. 

.. attention:: 

   This chapter assumes that the user has already built the Land DA System according to the instructions in :numref:`Section %s <BuildRunLandDA>` and has access to the data provided in the most recent release. (See :numref:`Table %s <Level1Data>` for the locations of pre-staged data on NOAA :term:`RDHPCS` [i.e., Hera and Orion].)

Process
*********

From the working directory (``$LANDDAROOT``), navigate to ``build``. Then run: 

.. code-block:: console
   
   salloc --ntasks 8 --exclusive --qos=debug --partition=<partition> --time=00:30:00 --account=<account_name>
   cd land-DA_workflow/sorc/build
   source ../../versions/build.ver_<platform>
   module use ../../modulefiles
   module load build_<platform>_intel 
   ctest

where ``<account_name>`` corresponds to the user's actual account name, ``<partition>`` is a valid partition on the platform of choice (e.g., ``debug`` or ``orion``), and ``<platform>`` is ``hera`` or ``orion``.

This will submit an interactive job, load the appropriate modulefiles, and run the CTests. 

If the tests are successful, a message will be printed to the console. For example:

.. code-block:: console

   Test project /work/noaa/epic/${USER}/landda/land-DA_workflow/sorc/build
       Start 1: test_vector2tile
   1/6 Test #1: test_vector2tile .................   Passed   12.01 sec
       Start 2: test_create_ens
   2/6 Test #2: test_create_ens ..................   Passed   13.91 sec
       Start 3: test_letkfoi_snowda
   3/6 Test #3: test_letkfoi_snowda ..............   Passed   67.94 sec
       Start 4: test_apply_jediincr
   4/6 Test #4: test_apply_jediincr ..............   Passed    6.88 sec
       Start 5: test_tile2vector
   5/6 Test #5: test_tile2vector .................   Passed   15.36 sec
       Start 6: test_ufs_datm_land
   6/6 Test #6: test_ufs_datm_land ...............   Passed   98.56 sec

   100% tests passed, 0 tests failed out of 6

   Total Test time (real) = 217.06 sec

Tests
*******

The ERA5 CTests test the operability of six major elements of the Land DA System: ``vector2tile``, ``create_ens``, ``letkfoi_snowda``, ``apply_jediincr``, ``tile2vector``, and ``ufs_datm_land``. The tests and their dependencies are listed in the ``land-DA_workflow/test/CMakeLists.txt`` file. Currently, the CTests are only run on Hera and Orion; they cannot yet be run via container. 

.. list-table:: *Land DA CTests*
   :widths: 20 50
   :header-rows: 1

   * - Test
     - Description
   * - ``test_vector2tile``
     - Tests the vector-to-tile function for use in JEDI
   * - ``test_create_ens``
     - Tests creation of a pseudo-ensemble for use in LETKF-OI.
   * - ``test_letkfoi_snowda``
     - Tests the use of LETKF-OI to assimilate snow DA. 
   * - ``test_apply_jediincr``
     - Tests the ability to add a JEDI increment.
   * - ``test_tile2vector``
     - Tests the tile-to-vector function for use in ``ufs-land-driver``
   * - ``test_ufs_datm_land``
     - Tests proper functioning of the UFS land model (``ufs-datm-lnd``)
