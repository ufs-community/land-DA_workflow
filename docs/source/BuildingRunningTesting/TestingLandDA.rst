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
   
   salloc --ntasks 8 --exclusive --qos=debug --partition=debug --time=00:30:00 --account=<account_name>
   module use modulefiles && module load landda_<platform>.intel 
   ctest

where ``<account_name>`` corresponds to the user's actual account name and ``<platform>`` is ``hera`` or ``orion``.

This will allocate a compute node, load the appropriate modulefiles, and run the CTests. 

Tests
*******

The ERA5 CTests test the operability of seven major elements of the Land DA System: ``vector2tile``, ``create_ens``, ``letkfoi_snowda``, ``apply_jediincr``, ``tile2vector``, ``land_driver``, and ``ufs_datm_land``. The tests and their dependencies are listed in the ``land-DA_workflow/test/CMakeLists.txt`` file. Currently, the CTests are only run on Hera and Orion; they cannot yet be run via container. 

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
   * - ``test_land_driver``
     - Tests proper functioning of ``ufs-land-driver``
   * - ``test_ufs_datm_land``
     - Tests proper functioning of the UFS land model (``ufs-datm-lnd``)
