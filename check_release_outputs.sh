#!/bin/sh 

# get OUTDIR
export SETTINGS_FILE=${1:-"settings_DA_cycle_gdas"}
source ./${SETTINGS_FILE}

export TEST_BASEDIR=${TEST_BASEDIR:-${EPICTESTS}}

function run_comp(){
    echo "testing ${state} on ${test_date}"
    cmp ${OUTDIR}/mem000/restarts/vector/ufs_land_restart_${state}.${test_date}.nc ${TEST_BASEDIR}/ufs_land_restart_${state}.${test_date}.nc

    if [[ $? != 0 ]]; then
    echo TEST FAILED
    echo "$test_date $state are different"
    exit 99
    fi
}

start_date=${STARTDATE::8}
start_hour=${STARTDATE:8}
end_date=${ENDDATE::8}


while [[ $start_date != $end_date ]]; do 
    test_date=$(date -d "$start_date $start_hour" +"%Y-%m-%d_%H-%M-%S")
    state='anal'
    run_comp
    
    # check back files for this date
    test_date=$(date -d "$start_date $start_hour + 1 day" +"%Y-%m-%d_%H-%M-%S")
    state='back'
    run_comp

    # Update start date formatted var
    start_date=$(date -d "$start_date + 1 day" +%Y%m%d)
done

echo "TEST PASSED"

exit
