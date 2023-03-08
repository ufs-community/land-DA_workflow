# unit testing
Unit Testing Framework for ufs-landDA System. We implemented ctest and pFUnit (unit testing for fortran). Currently land-offline_workflow supports 9 tests as shown below. Users who plan to `design/add` a new test should refer to `Adding test` for details on how to do so. At a minimum, these users will need to add the new test case to the `ufs-htf/test/CMakeLists.txt`, and add corresponding files in the `land-offline_workflow/test` folder.

```
$ ctest -N
Test project /work2/noaa/epic-ps/ycteng/land_DA/20230307/build
  Test #1: test_jediincr_module
  Test #2: test_python_compare_ecbuild
  Test #3: test_python_compare_ctest
  Test #4: test_vector2tile
  Test #5: test_create_ens
  Test #6: test_letkfoi_snowda
  Test #7: test_apply_jediincr
  Test #8: test_tile2vector
  Test #9: test_land_driver

Total Tests: 9
```

## Building and running the existing unit tests
Before you write your own unit tests, you should make sure that you can build and run the existing tests.

The following is an example of how to compile/build and run unit testing, on the Hera/Orion HPC.

```bash
# download input Data
wget https://epic-sandbox-srw.s3.amazonaws.com/landda-test-inps.tar.gz
tar xvfz landda-test-inps.tar.gz

# download source code
git clone -b unit_test_demo --recurse-submodules https://github.com/NOAA-EPIC/land-offline_workflow.git

# load the machine specific modules (now only support Hera/Orion, here we use Orion as example)
module use land-offline_workflow/modulefiles
module load landda_orion.intel

# git clone pFUint and build
export FC=mpiifort
export CC=mpiicc
export CXX=mpiicpc
git clone https://github.com/Goddard-Fortran-Ecosystem/pFUnit.git
mkdir -p pFUnit/build; cd $HOME/pFUnit/build; ecbuild ..; make -j2; make install

# compiling
cd ../land-offline_workflow
mkdir build
cd build
ecbuild .. -DCMAKE_PREFIX_PATH={YOUR ROOT PATH}/pFUnit/build/installed
make -j2

# grab a compute node and run ctests
salloc --ntasks 6 --exclusive --qos=windfall --time=00:05:00
#
module use ../modulefiles
module load landda_orion.intel
#
ctest --stop-on-failure

Screen output:

    Start 1: test_jediincr_module
1/9 Test #1: test_jediincr_module .............   Passed    2.56 sec
    Start 2: test_python_compare_ecbuild
2/9 Test #2: test_python_compare_ecbuild ......   Passed    0.71 sec
    Start 3: test_python_compare_ctest
3/9 Test #3: test_python_compare_ctest ........   Passed    0.30 sec
    Start 4: test_vector2tile
4/9 Test #4: test_vector2tile .................   Passed    8.83 sec
    Start 5: test_create_ens
5/9 Test #5: test_create_ens ..................   Passed    4.91 sec
    Start 6: test_letkfoi_snowda
6/9 Test #6: test_letkfoi_snowda ..............   Passed   76.93 sec
    Start 7: test_apply_jediincr
7/9 Test #7: test_apply_jediincr ..............   Passed    4.78 sec
    Start 8: test_tile2vector
8/9 Test #8: test_tile2vector .................   Passed    2.82 sec
    Start 9: test_land_driver
9/9 Test #9: test_land_driver .................   Passed    8.38 sec

100% tests passed, 0 tests failed out of 9

Label Time Summary:
landda    =   0.71 sec*proc (1 test)
script    =   0.71 sec*proc (1 test)

Total Test time (real) = 110.24 sec
```
# test with docker container
The following is an example of how to create docker image on NOAA cloud
```bash

# download source code
git clone -b unit_test_demo --recurse-submodules https://github.com/NOAA-EPIC/land-offline_workflow.git
cd land-offline_workflow

#
sudo systemctl start docker
sudo docker build --file "./test/ci/Dockerfile" -t ufs-noahmp_landa:develop .
sudo docker image inspect ufs-noahmp_landa:develop
```
## Add new test
We build the unit tests using a build system called CMake. There are a few steps needed to get your new unit tests to build alongside the others:

1. Add the new production module to the build system
2. Tell CMake about your new unit test directory
3. Add/Mod CMakeLists.txt file in your new unit test directory

Below we provide an example about how to add new GHCN iodacov unit test in land-offline_workflow. Here we assume we already have necessary files/scripts for this test (e.g. obs data, ioda converter to convert obs to ioda observation files, and run script)

To add new unit test, first add the following lines in land-offline_workflow/test/CMakeLists.txt:
```
# test iodacov to creat GHCN ioda file
add_test(NAME test_GHCN_ioda
         COMMAND ${PROJECT_SOURCE_DIR}/test/do_ghcn2ioda.sh ${PROJECT_BINARY_DIR} ${PROJECT_SOURCE_DIR}
         WORKING_DIRECTORY ${PROJECT_BINARY_DIR}/test)
```
This creates a test `test_GHCN_ioda` whose command runs land-offline_workflow/test/do_ghcn2ioda.sh shell script with 2 input arguments under build/test folder.

After adding these lines, we have to re-run ecbuild again:
```
ecbuild .. -DCMAKE_PREFIX_PATH={YOUR ROOT PATH}/pFUnit/build/installed
```
Now try ctest -N again. You will see a new test is added!
```
ctest -N
Test project /work2/noaa/epic-ps/ycteng/land_DA/20230307/build
  Test  #1: test_jediincr_module
  Test  #2: test_python_compare_ecbuild
  Test  #3: test_python_compare_ctest
  Test  #4: test_vector2tile
  Test  #5: test_create_ens
  Test  #6: test_letkfoi_snowda
  Test  #7: test_apply_jediincr
  Test  #8: test_tile2vector
  Test  #9: test_land_driver
  Test #10: test_GHCN_ioda

Total Tests: 10
```
Now we can test our new GHCN_ioda unit test:
```
ctest -R test_GHCN_ioda
Test project /work2/noaa/epic-ps/ycteng/land_DA/20230307/build
    Start 10: test_GHCN_ioda
1/1 Test #10: test_GHCN_ioda ...................   Passed    1.91 sec

100% tests passed, 0 tests failed out of 1

Total Test time (real) =   1.91 sec
```

## General guidelines for writing unit tests
Good unit tests test a single, well-defined condition. This generally means that you make a single call to the function / subroutine that you're testing, with a single set of inputs.Good unit tests are "FIRST":
* Fast (order milliseconds or less)
  * This means that, generally, they should not do any file i/o. Also, if you are testing a complex function, test it with a simple set of inputs - not a 10,000-element array that will require a few seconds of runtime to process.
* Independent
  * This means that test Y shouldn't depend on some global variable that was created by test X. Dependencies like this cause problems if the tests run in a different order, if one test is dropped, etc.
* Repeatable
  * This means, for example, that you shouldn't generate random numbers in your tests.
* Self-verifying
  * This means that you shouldn't write a test that writes out its answers for manual comparison. Tests should generate an automatic pass/fail result.
* Timely
  * This means that the tests should be written before the production code (Test Driven Development), or immediately afterwards - not six months later when it's time to finally merge your changes onto the trunk, and have forgotten the details of what you have written. Much of the benefit of unit tests comes from developing them alongside the production code.

## References
Below are some useful refernces:

* [Creating and running tests with CTest](https://coderefinery.github.io/cmake-workshop/testing/) for detailed usages of ctest.
* [cesm_unit_test_tutorial](https://github.com/NCAR/cesm_unit_test_tutorial#add-the-new-production-module-to-the-build-system) for detailed usages of pFUnit.
