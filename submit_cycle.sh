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

dates_per_job=5

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

echo "cycling from $startdate to $enddate" >> $logfile


thisdate=$startdate

date_count=0

#while [ $thisdate -le $enddate ]; do
while [ $date_count -lt $dates_per_job ]; do

    # substringing to get yr, mon, day, hr info
    export YYYY=`echo $thisdate | cut -c1-4`
    export MM=`echo $thisdate | cut -c5-6`
    export DD=`echo $thisdate | cut -c7-8`
    export HH=`echo $thisdate | cut -c9-10`

    # update model namelist 
    cp  template.ufs-noahMP.namelist.gswp3  ufs-land.namelist

    sed -i -e "s/YYYY/${YYYY}/g" ufs-land.namelist 
    sed -i -e "s/MM/${MM}/g" ufs-land.namelist
    sed -i -e "s/DD/${DD}/g" ufs-land.namelist
    sed -i -e "s/HH/${HH}/g" ufs-land.namelist
     
    # update snwo DA namelist
    cp  template.fort.36 fort.36

    sed -i -e "s/YYYY/${YYYY}/g"  fort.36
    sed -i -e "s/MM/${MM}/g" fort.36
    sed -i -e "s/DD/${DD}/g" fort.36
    sed -i -e "s/HH/${HH}/g" fort.36

    echo "Finished job number, ${date_count},for  date: ${thisdate}" >> $logfile

    thisdate=`${incdate} $thisdate 24`
    date_count=$((date_count+1))

    if [ $thisdate -gt $enddate ]; then 
        echo "All done, at date ${thisdate}"  >> $logfile
        exit 
    fi

    # submit snow DA 
    echo 'Running snow DA' >> $logfile
    srun '--export=ALL' -n 6 $snowDAexec

    # submit model
    echo 'Running model' >> $logfile
    $LSMexec

done

# resubmit
if [ $thisdate -le $enddate ]; then
    echo "export startdate=${thisdate}" > ${base_dir}/analdates.sh
    echo "export enddate=${enddate}" >> ${base_dir}/analdates.sh
    sbatch submit_cycle.sh
fi

