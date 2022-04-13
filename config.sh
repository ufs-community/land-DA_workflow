###########################
# experiment name
export exp_name=DA_IMS_test

############################
# model options
# ensemble_size of 1: LETKF-OI pseudo ensemble or do not run ensemble
export ensemble_size=1 

#options: gdas, gswp3, gefs_ens
export atmos_forc=gdas

# number of cycles to submit in a single job
export dates_per_job=1

############################
# DA options
export do_DA=YES 
export do_hofx=NO

# options: "letkfoi_snow" , "letkf_snow"
export DAtype=letkfoi_snow

export ASSIM_IMS=YES
export ASSIM_GHCN=NO
export ASSIM_SYNTH=NO
export ASSIM_GTS=NO
export CYCHR=24

############################
# set your directories

# temporary work dir
export WORKDIR=/scratch2/BMC/gsienkf/Clara.Draper/workdir/

# directory with initial conditions
# NOTE: ICS from this directory will be copied if they exist each time submit_cycle is called. 
# be careful is re-submitting submit_cycle to keep only the ICS here that you want to use.
export ICSDIR=/scratch2/BMC/gsienkf/Clara.Draper/DA_test_cases/offline_ICS/single/

# on hera - can use Clara's JEDI bundles.

# JEDI FV3 build directory
export JEDI_EXECDIR=/scratch2/BMC/gsienkf/Clara.Draper/jedi/build/bin/

# JEDI IODA-converter source directory
export IODA_BUILD_DIR=/scratch2/BMC/gsienkf/Clara.Draper/jedi/src/ioda-bundle/build/


############################
# optional directories - both default to current directory

# export EXPDIR # directory where output will be saved.
# export CYCLEDIR  # directory where cycleDA scripts are. 

