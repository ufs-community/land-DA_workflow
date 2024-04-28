#!/bin/bash
set -e
################################################
# pass arguments
project_binary_dir=$1
project_source_dir=$2

# Export runtime env. variables
source ${project_source_dir}/test/runtime_vars.sh ${project_binary_dir} ${project_source_dir}

# set extra paths
RSTDIR=$project_binary_dir/test/bkg/restarts/tile

# set executables
TEST_EXEC="${project_source_dir}/../ush/letkf_create_ens.py"
NPROC=1

# move to work directory
cd $WORKDIR

if [[ ${DAtype} == 'letkfoi_snow' ]]; then

    # FOR LETKFOI, CREATE THE PSEUDO-ENSEMBLE
    for ens in pos neg
    do
        #clean results from previous test
        if [ -e $WORKDIR/mem_${ens} ]; then
                rm -rf $WORKDIR/mem_${ens}
        fi

        mkdir -p $WORKDIR/mem_${ens}

        for i in ${RSTDIR}/${FILEDATE}.sfc_data.tile*.nc;
        do
            cp $i ${WORKDIR}/mem_${ens}
        done

        cres_file=$WORKDIR/mem_${ens}/${FILEDATE}.coupler.res
        cp ${project_source_dir}/../parm/templates/template.coupler.res $cres_file
        sed -i -e "s/XXYYYY/${YY}/g" $cres_file
        sed -i -e "s/XXMM/${MM}/g" $cres_file
        sed -i -e "s/XXDD/${DD}/g" $cres_file
        sed -i -e "s/XXHH/${HH}/g" $cres_file
        sed -i -e "s/XXYYYP/${YP}/g" $cres_file
        sed -i -e "s/XXMP/${MP}/g" $cres_file
        sed -i -e "s/XXDP/${DP}/g" $cres_file
        sed -i -e "s/XXHP/${HP}/g" $cres_file
    done


    echo "============================= calling create ensemble"
    ${MPIRUN} -n $NPROC $PYTHON_EXEC ${TEST_EXEC} $FILEDATE $SNOWDEPTHVAR $B 
fi
