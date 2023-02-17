help([[
loads Land DA prerequisites for Singularity/Intel
]])

setenv("EPICHOME", "/opt")

--prepend_path("MODULEPATH", pathJoin(os.getenv("EPICHOME"),"miniconda3/modulefiles"))
--miniconda3_ver=os.getenv("miniconda3_ver") or "4.12.0"
--load(pathJoin("miniconda3", miniconda3_ver))

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
setenv("JEDI_INSTALL", pathJoin(os.getenv("EPICHOME"),""))

whatis("Description: Land DA build environment")
