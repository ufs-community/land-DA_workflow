#!/bin/sh 

# get OUTDIR
export LANDDAROOT=${LANDDAROOT:-`dirname $PWD`}
export SETTINGS_FILE=${1:-"settings_sample_DA_cycle_test"}
echo $SETTINGS_FILE
source ./${SETTINGS_FILE}

EPICTESTS=${EPICHOME}/landda/cycle_land/DA_GHCN_test/mem000/restarts/vector
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
    exit
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
    exit
fi
done

echo "TEST PASSED"

exit
