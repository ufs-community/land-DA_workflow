Script to run cycling DA using JEDI in cube sphere space, and offline Noah-MP model in vector space. 

Clara Draper, Nov, 2021.

History 
Apr, 2022. Draper:  Moved to PSL repo, restructuring and renaming of repos.

#############################

COMPILING and TESTING.

1. Fetch sub-modules.
>git submodule update --init --recursive

2. Compile sub-modules.

2a. 
> cd vector2tile 
  then follow instructions in README. 
> cd .. 

2b. 
> cd ufs-land-driver

> git submodule update --init (if did not use --recursive flag above) 

> configure 
   
  select hera, load indicated modules 

> make 

2c.
> cd DA_update
  then follow instructions in README.

3. Run the test.

 change WORKDIR in settings_DA_IMS_test to point to your own directory. 

> sbatch submit_cycle.sh settings_DA_IMS_test

Once run, check if passed.

> check_test_passed.sh

RUNNING YOUR OWN EXPERIMENTS 

1. Prepare a settings file, using settings_template. Must fill in all variables, unless otherwise commented. 

2. Set start and end dates in analdates.sh 

3. Make sure there is a restart in your ICSDIR, and that the start date in analdates.sh match the restart. 

restart filename example:ufs_land_restart.2015-09-02_18-00-00.nc 
ICSDIR points to the experiment directory with the restart. If creating a new dircetory, the structure is: 
$ICSDIR/output/modl/restarts/vector/ufs_land_restart.2015-09-02_18-00-00.nc 

4. Submit your job 

>sbatch submit_cycle.sh your-settings-filename

