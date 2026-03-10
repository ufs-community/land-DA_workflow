help([[
loads UFS Model prerequisites for Singularity container
]])

setenv("EPICHOME", "/opt")

prepend_path("MODULEPATH", pathJoin(os.getenv("EPICHOME"),"spack-stack/spack-stack-1.9.2/envs/unified-env/install/modulefiles/Core"))
prepend_path("MODULEPATH", pathJoin(os.getenv("EPICHOME"),"spack-stack/spack-stack-1.9.2/envs/unified-env/install/modulefiles/intel-oneapi-mpi/2021.13-argr3sd/gcc/11.4.0"))

stack_intel_ver=os.getenv("stack_intel_ver") or "2024.2.0"
load(pathJoin("stack-oneapi", stack_intel_ver))

stack_intel_oneapi_mpi_ver=os.getenv("stack_intel_oneapi_mpi_ver") or "2021.13"
load(pathJoin("stack-intel-oneapi-mpi", stack_intel_oneapi_mpi_ver))

cmake_ver=os.getenv("cmake_ver") or "3.27.9"
load(pathJoin("cmake", cmake_ver))

ecbuild_ver=os.getenv("ecbuild_ver") or "3.7.2"
load(pathJoin("ecbuild", ecbuild_ver))

load("ufs_common")

nccmp_ver=os.getenv("nccmp_ver") or "1.9.0.1"
load(pathJoin("nccmp", nccmp_ver))

nco_ver=os.getenv("nco_ver") or "5.2.4"
load(pathJoin("nco", nco_ver))

nemsio_ver=os.getenv("nemsio_ver") or "2.5.4"
load(pathJoin("nemsio", nemsio_ver))

sfcio_ver=os.getenv("sfcio_ver") or "1.4.2"
load(pathJoin("sfcio", sfcio_ver))

sigio_ver=os.getenv("sigio_ver") or "2.3.3"
load(pathJoin("sigio", sigio_ver))

zlib_ver=os.getenv("zlib_ver") or "1.2.11"
load(pathJoin("zlib", zlib_ver))

-- Load python specific packages 
load("py-cftime/1.0.3.4")
load("py-cython/3.0.11")
load("py-f90nml/1.4.3")
load("py-jinja2/3.1.4")
load("py-netcdf4/1.7.1.post2")
load("py-numpy/1.26.4")
load("py-pandas/2.2.3")
load("py-python-dateutil/2.8.2")
load("py-pyyaml/6.0.2")

prepend_path("PATH","/opt/intel/oneapi/compiler/2024.2/bin")
setenv("I_MPI_ROOT","/opt/intel/oneapi/mpi/2021.13")
setenv("CC", "mpiicc")
setenv("CXX", "mpiicpc")
setenv("FC", "mpiifort -diag-disable=10448")

setenv("JEDI_PATH", pathJoin(os.getenv("EPICHOME"),""))

whatis("Description: UFS build environment")
