# unit testing
Unit Testing Framework for ufs-landDA System. We implemented both ctest and pFUnit (unit testing for fortran). Currently the UFS-HTF supports nine tests as shown in Table 2.1. Users who plan to design/add a new test should refer to Adding test for details on how to do so. At a minimum, these users will need to add the new test case to the ufs-htf/test/CMakeLists.txt script and add the corresponding files in the land-offline_workflow
/test folder. :

```
git clone https://github.com/JCSDA/soca.git
mkdir -p soca_build
cd soca_build
ecbuild ../soca/bundle
cd soca
make -j 4
```

* building ufs model and its utilities;
* staging model input data from AWS S3 bucket;
* atm-only run for 2019 Hurricane Barry (C96 grid; based on global workflow)
* atm-ocn-ice coupled run for 2019 Hurricane Barry (C96 grid; based on global workflow)
* atm-ocn-ice-wav coupled run for 2019 Hurricane Barry (C96 grid; based on global workflow)
* atm-ocn-ice-wav-a coupled run for 2019 Hurricane Barry (C96 grid; based on global workflow)
* vrfy1: hurricane track check
* vrfy2: comparsion between model and reanalysis/obs
* atm-ocn-ice coupled run for 2019 Hurricane Barry (C96 grid, fcst step only)


## How to use

Please see [User Guide](https://ufs-htf.readthedocs.io/en/latest/BuildHTF.html#download-the-ufs-htf-prototype) for details.
