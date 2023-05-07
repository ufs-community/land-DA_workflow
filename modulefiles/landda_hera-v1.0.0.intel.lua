help([[
loads Land DA prerequisites for Hera/Intel
]])

setenv("EPICHOME", "/scratch1/NCEPDEV/nems/role.epic")

prepend_path("MODULEPATH", pathJoin(os.getenv("EPICHOME"),"miniconda3/modulefiles"))

load("miniconda3/4.12.0")

prepend_path("MODULEPATH", pathJoin(os.getenv("EPICHOME"),"spack-stack/envs/landda-release-1.0-intel/install/modulefiles/Core"))

load("stack-intel")
load("stack-intel-oneapi-mpi")
load("netcdf-c")
load("netcdf-fortran")
load("cmake")
load("ecbuild")
load("stack-python")

setenv("CC", "mpiicc")
setenv("CXX", "mpiicpc")
setenv("FC", "mpiifort")
setenv("JEDI_INSTALL", pathJoin(os.getenv("EPICHOME"),"contrib"))

whatis("Description: Land DA build environment")
