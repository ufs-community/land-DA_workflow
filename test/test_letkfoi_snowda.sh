#!/bin/bash
set -e
################################################
# pass arguments
project_binary_dir=$1
project_source_dir=$2

# Export runtime env. variables
source ${project_source_dir}/test/runtime_vars.sh ${project_binary_dir} ${project_source_dir}

# set extra paths
OROG_PATH=$TPATH
OBSDIR=${LANDDA_INPUTS}/DA/snow_depth

# set executables
JEDI_EXEC=${JEDI_EXEC:-$JEDI_EXECDIR/fv3jedi_letkf.x}
NPROC=6

# move to work directory
cd $WORKDIR

# Clean test files created during a previous test
[[ -e letkf_land.yaml ]] && rm letkf_land.yaml
[[ -e output/DA/hofx ]] && rm -rf output/DA/hofx
for i in ./${FILEDATE}.xainc.sfc_data.tile*.nc;
do
  [[ -e $i ]] && rm $i
done

# prepare yaml files
cp $project_source_dir/DA_update/jedi/fv3-jedi/yaml_files/release-v1.0/${DAtype}.yaml letkf_land.yaml
for ii in "${!OBS_TYPES[@]}";
do
    echo "============================= ${OBS_TYPES[$ii]}" 
    cat $project_source_dir/DA_update/jedi/fv3-jedi/yaml_files/release-v1.0/${OBS_TYPES[$ii]}.yaml >> letkf_land.yaml

    # link ioda obs file
    [[ -e ${OBS_TYPES[$ii]}_${YY}${MM}${DD}${HH}.nc ]] && rm ${OBS_TYPES[$ii]}_${YY}${MM}${DD}${HH}.nc
    src_file=${OBSDIR}/${OBS_TYPES[$ii]}/data_proc/${YY}/${OBS_TYPES[$ii],,}_snwd_ioda_${YY}${MM}${DD}.nc
    ln -fs ${src_file} ./${OBS_TYPES[$ii]}_${YY}${MM}${DD}${HH}.nc 

done

sed -i -e "s/XXYYYY/${YY}/g" letkf_land.yaml
sed -i -e "s/XXMM/${MM}/g" letkf_land.yaml
sed -i -e "s/XXDD/${DD}/g" letkf_land.yaml
sed -i -e "s/XXHH/${HH}/g" letkf_land.yaml
sed -i -e "s/XXYYYP/${YP}/g" letkf_land.yaml
sed -i -e "s/XXMP/${MP}/g" letkf_land.yaml
sed -i -e "s/XXDP/${DP}/g" letkf_land.yaml
sed -i -e "s/XXHP/${HP}/g" letkf_land.yaml
sed -i -e "s#DATAPATH#${OROG_PATH}#g" letkf_land.yaml
sed -i -e "s/XXRES/${RES}/g" letkf_land.yaml
RESP1=$((RES+1))
sed -i -e "s/XXREP/${RESP1}/g" letkf_land.yaml
sed -i -e "s/XXHOFX/false/g" letkf_land.yaml  # do DA

# create folder for hofx
mkdir -p ./output/DA/hofx

# link jedi static files
ln -fs $JEDI_STATICDIR ./

#
echo "============================= calling ${JEDI_EXEC}"
${MPIRUN} -n $NPROC ${JEDI_EXEC} letkf_land.yaml
