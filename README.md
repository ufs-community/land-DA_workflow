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

 in settings_cycle_test check WORKDIR and OUTDIR are OK
 create OUTDIR
 in submit_cycle.sh change #SBATCH --account=gsienkf to point to your own account.

> submit_test.sh 

Once completed:

> check_test.sh

RUNNING YOUR OWN EXPERIMENTS 

1. Prepare a settings file, using settings_template. Must fill in all variables, unless otherwise commented. 

2. Set start and end dates in analdates.sh 

3. Make sure there is a restart in your ICSDIR, and that the start date in analdates.sh match the restart. 

restart filename example:ufs_land_restart.2015-09-02_18-00-00.nc 
ICSDIR points to the experiment directory with the restart. If creating a new dircetory, the structure is: 
$ICSDIR/output/modl/restarts/vector/ufs_land_restart.2015-09-02_18-00-00.nc 

4. in submit_cycle.sh change #SBATCH --account=gsienkf to point to your own account.

5. Submit your job 

>sbatch submit_cycle.sh your-settings-filename

#############################

build steps with cmake: jedi stack works ok on orion but need to follow up jedi stack on hera.

1. git clone -b feature/bundle-cmake https://github.com/jkbk2004/land-offline_workflow-1

2. cd land-offline_workflow-1/

3. git submodule update --init --recursive

4. mkdir build

5. source configures/machine.orion.intel

6. cd build/

7. ecbuild ..

8. make -j 1
