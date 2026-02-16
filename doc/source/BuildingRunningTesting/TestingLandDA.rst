.. _TestingLandDA:

************************************
Testing the Land DA Workflow
************************************

This chapter provides instructions for using the Land DA CTest suite. These steps are designed for use on :ref:`Level 1 <LevelsOfSupport>` systems (e.g., Ursa and Hercules) and may require significant changes on other systems. 

.. attention:: 

   This chapter assumes that the user has already built the Land DA System according to the instructions in :numref:`Section %s <BuildRunLandDA>` and has access to the data provided in the most recent release. (See :numref:`Table %s <Level1Data>` for the locations of pre-staged data on NOAA :term:`RDHPCS`.)


Test Descriptions
===================

The CTests test the operability of four major elements of the Land DA System: ``create_ens``, ``letkfoi_snowda``, ``apply_jediincr``, and ``ufs_datm_land``. The tests and their dependencies are listed in the ``land-DA_workflow/test/CMakeLists.txt`` file. 

.. list-table:: *Land DA CTests*
   :widths: 20 50
   :header-rows: 1

   * - Test
     - Description
   * - ``test_create_ens``
     - Tests creation of a pseudo-ensemble for use in :term:`LETKF-OI`.
   * - ``test_letkfoi_snowda``
     - Tests the use of LETKF-OI to assimilate snow data. 
   * - ``test_apply_jediincr``
     - Tests the ability to add a JEDI increment.
   * - ``test_ufs_datm_land``
     - Tests proper functioning of the UFS land model (``ufs-datm-lnd``)

.. COMMENT: Check this! Currently, WE2E test seems to fail

.. note::

   There are plans to add workflow end-to-end (WE2E) tests to the Land DA System. Currently, when ``WE2E_TEST: "YES"``, this functionality checks that the output from the Jan. 3-4, 2000 sample case is within the tolerance set (via the ``WE2E_ATOL`` variable) at the end of the three main tasks --- *analysis*, *forecast*, and *post_anal*. The results are logged by default in ``we2e.log``. In the future, this functionality will be expanded to encompass a full range of WE2E tests. 

Testing on Level 1 Systems
============================

After cloning the ``develop`` branch and running ``./app_build.sh`` to build the Land DA System (:numref:`Section %s <GetCode>`), navigate to the ``test`` directory: 

.. code-block:: console
   
   cd ${BASEDIR}/land-DA_workflow/sorc/test

If necessary, open ``run_<machine>_ctest.sh`` (where ``<machine>`` is ``ursa``, ``orion``, ``hercules``, or ``gaeac6``) and change both instances of the ``--account`` variable to the name of an account you can run on. The default is ``--account=epic``. 

.. code-block:: console
   
   vim run_<machine>_ctest.sh

Save changes and exit by typing ``:wq``. 

Then, run the CTest script: 

.. code-block:: console
   
   ./run_ctest_platform.sh

To check the results, navigate to the ``build`` directory and view the ``out.ctest`` file: 

.. code-block:: console 
   
   cd ../build
   vim out.ctest

The bottom of the ``out.ctest`` file will include a message with test results. For example:

.. code-block:: console

   Test project ${BASEDIR}/land-DA_workflow/sorc/build
      Start 1: test_create_ens
   1/4 Test #1: test_create_ens ..................   Passed   14.57 sec
      Start 2: test_letkfoi_snowda
   2/4 Test #2: test_letkfoi_snowda ..............   Passed   19.27 sec
      Start 3: test_apply_jediincr
   3/4 Test #3: test_apply_jediincr ..............   Passed    1.47 sec
      Start 4: test_ufs_datm_land
   4/4 Test #4: test_ufs_datm_land ...............   Passed   31.55 sec

   100% tests passed, 0 tests failed out of 4

   Total Test time (real) =  66.90 sec

If one or more tests fail, users can check the logs at ``${BASEDIR}/land-DA_workflow/sorc/build/Testing/Temporary/LastTest.log`` for more information on the failure.

Running Tests Using a Container
=================================

.. COMMENT: Update this container section for the release

.. attention::

   The container CTest functionality has been tested in Jenkins. It should be able to run on a sufficiently large cloud instance. However, it is considered unsupported functionality because it has not been thoroughly tested on the cloud for use by the public. 

For containers, the CTest functionality is wrapped in a Dockerfile. Therefore, users will need to build the Dockerfile to run the CTests. Since the Land DA container is quite large, this process can take a long time --- potentially hours. In the future, the development team hopes to simplify and shorten this process. 

.. code-block:: console

   git clone -b release/public-v2.0.0 --recursive https://github.com/ufs-community/land-DA_workflow.git
   cd land-DA_workflow/sorc/test/ci
   sudo systemctl start docker
   sudo docker build -f Dockerfile -t dockerfile-ci-ctest:release .

.. note::
   
   ``sudo`` may not be required in front of the last two commands on all systems. 
