#!/usr/bin/env bash
#
# A unified test script for the Land-DA_workflow application. This script is expected to
# test Land-DA_workflow model for any supported platforms.
#
# Usage:
#  UFS_PLATFORM=<platform> UFS_COMPILER=<compiler> [ LAND_DA_EXPERIMENT=<exp> ] .cicd/scripts/run_experiment.sh
#  .cicd/scripts/land_experiment.sh <platform> <compiler> [ <experiment>|default ]
#
pwd
export REPO_NAME="land-DA_workflow"

status=0

[[ -n $1 ]] && export UFS_PLATFORM=${1} || status=1
[[ -n $2 ]] && export UFS_COMPILER=${2} || :
[[ -n $3 ]] && export LAND_DA_EXPERIMENT=${3} || :

[[ -n ${workspace} ]] || export workspace=$(pwd)

echo "workspace=${workspace}"
echo "HOME=${HOME}"

echo "UFS_PLATFORM=${UFS_PLATFORM}"
echo "UFS_COMPILER=${UFS_COMPILER}"
echo "LAND_DA_EXPERIMENT=${LAND_DA_EXPERIMENT}"

# Test
cd ${workspace}
pwd
export machine=${UFS_PLATFORM,,}
export compiler=${UFS_COMPILER:-intel}
export LAND_DA_EXPERIMENT="${LAND_DA_EXPERIMENT:-}"
echo "machine=${machine}"
echo "compiler=${compiler}"

#export exp_basedir=${expbasedir:-$(dirname $(pwd))}
export exp_basedir=${exp_basedir:-$(pwd)}

[[ ${machine} = gaeac6   ]] && export ACCNR="bil-fire8" || :  # bil-fire8
[[ ${machine} = hera     ]] && export ACCNR="nems"      || :  # nral0032
[[ ${machine} = hercules ]] && export ACCNR="epic"      || :
[[ ${machine} = orion    ]] && export ACCNR="epic"      || :
echo "ACCNR=${ACCNR}"

# Choice of experiment that is supported on the machine.
experiment="${LAND_DA_EXPERIMENT:-}"
if [[ ${LAND_DA_EXPERIMENT} = default ]] ; then
	experiment="LND.gswp3.3dvar.ghcn.coldstart"
elif [[ ${LAND_DA_EXPERIMENT} = coverage ]] ; then
	[[ ${machine} = gaeac6   ]] && experiment="LND.era5.3dvar.ims.warmstart"   || :
	[[ ${machine} = hera     ]] && experiment="LND.era5.letkf.ghcn.coldstart"  || :
	[[ ${machine} = hercules ]] && experiment="LND.gswp3.letkf.ghcn.warmstart" || :
	[[ ${machine} = orion    ]] && experiment="LND.gswp3.3dvar.ghcn.coldstart" || :
else
	:
fi

if [[ -n ${experiment} ]] && [[ ${status} = 0 ]] ; then
	echo "Pipeline Running Land-DA Experiment on ${machine} with Account=${ACCNR}."

	# Make sure we have binaries and libraries ...
	ls -l ./sorc/build/bin/*.exe ./sorc/build/lib64/*.so
	status=$?
	if [[ ${status} = 0 ]] ; then # We have what we need to run ...

	    pwd
	    export HOMElandda="$(pwd)"
	    export APP_DIR="."
	    export workspace=${workspace:-$(pwd)}

	    rm -f *wflow_*

	    cd ${HOMElandda}/${APP_DIR}
	    git branch -av
	    set +x

	    source versions/run.ver_${machine}
	    module use modulefiles
	    module load wflow_${machine} || true
	    conda activate land_da || true

	    echo "PATH=${PATH}"

	    cd ${HOMElandda}/${APP_DIR}
	    ls -l parm/config_samples/
	    if [[ ! -f parm/config_samples/config.${experiment}.yaml ]] ; then
		echo "experiment=${experiment} not found."
	    else
		cd ${HOMElandda}/${APP_DIR}/parm
		sed "s|^ACCOUNT: epic|ACCOUNT: ${ACCNR}|1" config_samples/config.${experiment}.yaml > config.yaml
		[[ -f config.yaml ]] && ./setup_wflow_env.py -p ${machine} || echo "no config.yaml ..."

		cd ${HOMElandda}/${APP_DIR}
		ENVIR=$(grep envir: parm/config.yaml | awk '{printf "%s", $2}')

		echo "#### clean envir: ptmp/${ENVIR}"
		[[ -d ${HOMElandda}/../ptmp/${ENVIR} ]] && rm -rf ${HOMElandda}/../ptmp/${ENVIR} || :
		[[ -d ${HOMElandda}/ptmp/${ENVIR} ]] && rm -rf ${HOMElandda}/ptmp/${ENVIR} || :

		EXP_CASE_NAME=$(grep EXP_CASE_NAME: parm/config.yaml | awk '{printf "%s", $2}')
		if [[ -d ${exp_basedir}/exp_case/${EXP_CASE_NAME} ]] ; then
		    cd ${exp_basedir}/exp_case/${EXP_CASE_NAME}
		    cp land_analysis.yaml ${workspace}/${machine}-wflow_experiment.yaml
		    set +x
		    grep exp_basedir: land_analysis.yaml | tr -d '"' #| awk '{printf "%s", $2}'
		    done=false
		    loop=0
		    until [ $done = true ] ; do
			echo "$(date) ${machine} loop: $(( ++loop )) "
			./launch_rocoto_wflow.sh
			sleep 2
			rocotostat -w land_analysis.xml -d land_analysis.db | tee ${workspace}/${machine}-wflow_experiment-log.txt
		        echo -e "\nExperimentConf=${experiment}" | tee -a log.rocoto_launch
			pwd
			ls -l log.rocoto_launch
			# Check to see if we are done ...
			[[ $(cat log.rocoto_launch | grep '^2' | awk '{print $4}' | sort -u) =~ DEAD ]] && break || true
			[[ $(cat log.rocoto_launch | grep '^2' | awk '{print $4}' | sort -u) =~ '-'  ]] \
			    || [[ $(cat log.rocoto_launch | grep '^2' | awk '{print $4}' | sort -u) =~ 'QUEUED'  ]] \
			    || [[ $(cat log.rocoto_launch | grep '^2' | awk '{print $4}' | sort -u) =~ 'RUNNING'  ]] \
			    || [[ $(cat log.rocoto_launch | grep '^2' | awk '{print $4}' | sort -u) =~ 'SUBMITTING'  ]] \
			    || break
			sleep 120
		    done
		    sleep 10
		    cat log.rocoto_launch | tee ${workspace}/${machine}-wflow_experiment-log.txt
		    (( status+=${PIPESTATUS[0]} ))
		else
		    echo "no experiment directory ..."
		fi
		cd ${HOMElandda}/${APP_DIR}
		#rm -rf sorc/conda
	    fi

	    [[ -f ${workspace}/${machine}-wflow_experiment-log.txt ]] || (( status+=1 ))
	    rc=$(( status+=$(egrep "FAILURE|DEAD" ${workspace}/${machine}-wflow_experiment-log.txt 2>/dev/null | wc -l) ))
	    echo "rc=$rc status=$status"
	    set -x
	else
	    echo "Error: bin/* or lib64/* not available."
	fi
	echo "Pipeline Completed Land-DA Experiment on ${machine}. status=$status"
else
	echo "Pipeline skipping Experiment on ${machine}"
fi

exit ${status}

