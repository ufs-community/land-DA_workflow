-- temporary solution, need to updated when spack-stack is updated
--
prepend_path("MODULEPATH", '/work/noaa/epic/role-epic/spack-stack/hercules/spack-stack-1.7.0/envs/ue-intel/install/modulefiles/Core')

load(pathJoin("stack-intel", "2021.9.0"))
load(pathJoin("stack-intel-oneapi-mpi", "2021.9.0"))

load(pathJoin("prod_util", "2.1.1"))

load(pathJoin("py-cartopy", "0.21.1"))
load(pathJoin("py-matplotlib", "3.7.4"))
load(pathJoin("py-netcdf4", "1.5.8"))
load(pathJoin("py-numpy", "1.22.3"))
load(pathJoin("py-pandas", "1.5.3"))
load(pathJoin("py-pyyaml", "6.0"))

