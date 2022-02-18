Script to run cycling DA using JEDI in cube sphere space, and offline Noah-MP model in vector space. 

Clara Draper, Nov, 2021.

To install and build: 

1. Fetch sub-modules.
>git submodule update --init

2. Compile sub-modules.

> cd vector2tile 
  then follow instructions in README. 
> cd .. 

> cd ufs_land_driver
   build ufsLand.exe following the "Pre 2021-12-06" instructions:
   https://github.com/barlage/ufs-land-driver/wiki/Some-basic-instructions-for-running-the-UFS-land-driver

> cd landDA_workflow 
  then follow instructions in README.

3. Put vector restart in this directory. 

filename example:ufs_land_restart.2015-09-02_18-00-00.nc

4. Set start and end dates in analdates.sh 

5. Set directories and DA options at top of submit_cycle.sh 

To run: 
>submit_cycle.sh
