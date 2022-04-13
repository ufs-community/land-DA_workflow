#!/bin/sh 

TEST_BASEDIR=/scratch2/BMC/gsienkf/Clara.Draper/DA_test_cases/land-offline_workflow/DA_IMS_test/output/modl/restarts/vector/

TEST_DATE=2016-01-03_18-00-00

echo 'comparing results, differences will be below (if no further output, test passed)' 
cmp ./exp_out/DA_IMS_test/output/modl/restarts/vector/ufs_land_restart_back.${TEST_DATE}.nc ${TEST_BASEDIR}/ufs_land_restart_back.${TEST_DATE}.nc
