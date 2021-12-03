#! /bin/sh -l
#SBATCH --job-name=offline_noahmp
#SBATCH --account=gsienkf
#SBATCH --qos=debug
#SBATCH --nodes=1
#SBATCH --tasks-per-node=6
#SBATCH --cpus-per-task=1
#SBATCH -t 00:10:00
#SBATCH -o log_noahmp.%j.log
#SBATCH -e err_noahmp.%j.err
#SBATCH --export=NONE

# set your executables
snowDAexec=/scratch2/BMC/gsienkf/Tseganeh.Gichamo/global-workflow/exec/driver_snowda
LSMexec=/scratch2/BMC/gsienkf/Clara.Draper/gerrit-hera/noahMP_driver/cycleOI/ufs_land_driver/ufsLand.exe 
vec2tileexec=/scratch2/BMC/gsienkf/Clara.Draper/vector2tile/vector2tile_converter.exe

dates_per_job=20

# shouldn't need to change anything below here
base_dir=$(pwd)
incdate=$base_dir/incdate.sh

#source /home/Azadeh.Gholoubi/.my_mods 
module load intel
module load netcdf/4.7.0

# probably don't need this.
export LD_LIBRARY_PATH=/apps/hdf5/1.10.5/intel/18.0.5.274/lib:/apps/nco/4.7.0/intel/18.0.3.051/lib:/apps/netcdf/4.7.4/intel/18.0.5/lib:/apps/pnetcdf/1.10.0/intel/16.1.150/impi/5.1.2.150/lib:/apps/wgrib2/2.0.8/intel/18.0.3.222/lib:/apps/intel/compilers_and_libraries_2018/linux/mpi/intel64/lib::/apps/slurm/default/lib:/apps/intel/parallel_studio_xe_2018.4.057/compilers_and_libraries_2018/linux/compiler/lib/intel64:/apps/intel/parallel_studio_xe_2018.4.057/compilers_and_libraries_2018/linux/ipp/lib/intel64:/apps/intel/parallel_studio_xe_2018.4.057/compilers_and_libraries_2018/linux/compiler/lib/intel64_lin:/apps/intel/parallel_studio_xe_2018.4.057/compilers_and_libraries_2018/linux/mkl/lib/intel64_lin:/apps/intel/parallel_studio_xe_2018.4.057/compilers_and_libraries_2018/linux/tbb/lib/intel64/gcc4.7:/apps/intel/parallel_studio_xe_2018.4.057/debugger_2018/libipt/intel64/lib:/apps/intel/parallel_studio_xe_2018.4.057/compilers_and_libraries_2018/linux/daal/lib/intel64_lin:/apps/intel/parallel_studio_xe_2018.4.057/compilers_and_libraries_2018/linux/daal/../tbb/lib/intel64_lin/gcc4.4:$LD_LIBRARY_PATH

# read in dates 
source $base_dir/analdates.sh

logfile=$base_dir/cycle.log
touch $logfile

echo "***************************************" >> $logfile
echo "cycling from $startdate to $enddate" >> $logfile

thisdate=$startdate

date_count=0

#while [ $thisdate -le $enddate ]; do
while [ $date_count -lt $dates_per_job ]; do

    if [ $thisdate -ge $enddate ]; then 
        echo "All done, at date ${thisdate}"  >> $logfile
        exit 
    fi

    echo "starting $thisdate"  

    # substringing to get yr, mon, day, hr info
    export YYYY=`echo $thisdate | cut -c1-4`
    export MM=`echo $thisdate | cut -c5-6`
    export DD=`echo $thisdate | cut -c7-8`
    export HH=`echo $thisdate | cut -c9-10`

    # update model namelist 
    cp  template.ufs-noahMP.namelist.gswp3  ufs-land.namelist

    sed -i -e "s/XXYYYY/${YYYY}/g" ufs-land.namelist 
    sed -i -e "s/XXMM/${MM}/g" ufs-land.namelist
    sed -i -e "s/XXDD/${DD}/g" ufs-land.namelist
    sed -i -e "s/XXHH/${HH}/g" ufs-land.namelist
     
    # update vec2tile and tile2vec namelists
    cp  template.vector2tile vector2tile.namelist

    sed -i -e "s/XXYYYY/${YYYY}/g" vector2tile.namelist
    sed -i -e "s/XXMM/${MM}/g" vector2tile.namelist
    sed -i -e "s/XXDD/${DD}/g" vector2tile.namelist
    sed -i -e "s/XXHH/${HH}/g" vector2tile.namelist

    cp  template.tile2vector tile2vector.namelist

    sed -i -e "s/XXYYYY/${YYYY}/g" tile2vector.namelist
    sed -i -e "s/XXMM/${MM}/g" tile2vector.namelist
    sed -i -e "s/XXDD/${DD}/g" tile2vector.namelist
    sed -i -e "s/XXHH/${HH}/g" tile2vector.namelist

    # save input restart
    cp restarts/vector/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc restarts/vector/ufs_land_restart_back.${YYYY}-${MM}-${DD}_${HH}-00-00.nc

    # submit vec2tile 
    echo '************************************************'
    echo 'calling vector2tile' 
    $vec2tileexec vector2tile.namelist
    if [[ $? != 0 ]]; then
        echo "vec2tile failed"
        exit 
    fi

    # submit snow DA 

    # submit tile2vec
    echo '************************************************'
    echo 'calling tile2vector' 
    $vec2tileexec tile2vector.namelist
    if [[ $? != 0 ]]; then
        echo "tile2vector failed"
        exit 
    fi

    # submit model
    echo '************************************************'
    echo 'calling model' 
#    $LSMexec
# no error codes on exit from model, check for restart below instead
#    if [[ $? != 0 ]]; then
#        echo "model failed"
#        exit 
#    fi

    if [[ -e restarts/vector/ufs_land_restart.${YYYY}-${MM}-${DD}_${HH}-00-00.nc ]]; then 
       echo "Finished job number, ${date_count},for  date: ${thisdate}" >> $logfile
    else 
       echo "Something is wrong, probably the model, exiting" 
       exit
    fi

    thisdate=`${incdate} $thisdate 24`
    date_count=$((date_count+1))

done

# resubmit
if [ $thisdate -lt $enddate ]; then
    echo "export startdate=${thisdate}" > ${base_dir}/analdates.sh
    echo "export enddate=${enddate}" >> ${base_dir}/analdates.sh
    sbatch submit_cycle.sh
fi

