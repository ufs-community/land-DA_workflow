#!/bin/bash -le

rm -rf exp_out/DA_IMS_test 
mv analdates.sh analdates.sh_

touch analdates.sh 
cat << EOF > analdates.sh
export STARTDATE=2016010118
export ENDDATE=2016010318
EOF

sbatch submit_cycle.sh settings_cycle_test



