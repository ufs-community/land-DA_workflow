#!/bin/sh 

# get OUTDIR
export SETTINGS_FILE=${1:-"settings_DA_cycle_gdas"}
source ./${SETTINGS_FILE}

export TEST_BASEDIR=${TEST_BASEDIR:-${EPICTESTS}}

for TEST_DATE in 2016-01-01_18-00-00 2016-01-02_18-00-00 
do

for state in anal
do 

cmp ${OUTDIR}/mem000/restarts/vector/ufs_land_restart_${state}.${TEST_DATE}.nc ${TEST_BASEDIR}/ufs_land_restart_${state}.${TEST_DATE}.nc

echo "testing ${state} on ${TEST_DATE}"
if [[ $? != 0 ]]; then
    echo TEST FAILED
    echo "$TEST_DATE $state are different"
    exit 98
fi

done
done 

#TEST_DATE=2016-01-03_18-00-00
for TEST_DATE in 2016-01-02_18-00-00 2016-01-03_18-00-00 
do
state='back'
echo "testing ${state} on ${TEST_DATE}"
cmp ${OUTDIR}/mem000/restarts/vector/ufs_land_restart_${state}.${TEST_DATE}.nc ${TEST_BASEDIR}/ufs_land_restart_${state}.${TEST_DATE}.nc

if [[ $? != 0 ]]; then
    echo TEST FAILED
    echo "$TEST_DATE $state are different"
    exit 99
fi
done

echo "TEST PASSED"

exit
