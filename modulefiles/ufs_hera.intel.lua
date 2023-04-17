help([[
loads UFS Model prerequisites for Hera/Intel
]])

prepend_path("MODULEPATH", "/scratch1/NCEPDEV/nems/role.epic/spack-stack/spack-stack-1.3.0/envs/unified-env/install/modulefiles/Core")
prepend_path("MODULEPATH", "/scratch1/NCEPDEV/jcsda/jedipara/spack-stack/modulefiles")

stack_intel_ver=os.getenv("stack_intel_ver") or "2021.5.0"
load(pathJoin("stack-intel", stack_intel_ver))

stack_impi_ver=os.getenv("stack_impi_ver") or "2021.5.1"
load(pathJoin("stack-intel-oneapi-mpi", stack_impi_ver))

stack_python_ver=os.getenv("stack_python_ver") or "3.9.12"
load(pathJoin("stack-python", stack_python_ver))

cmake_ver=os.getenv("cmake_ver") or "3.23.1"
load(pathJoin("cmake", cmake_ver))

ecbuild_ver=os.getenv("ecbuild_ver") or "3.6.5"
load(pathJoin("ecbuild", ecbuild_ver))

load("ufs_common")

setenv("CC", "mpiicc")
setenv("CXX", "mpiicpc")
setenv("FC", "mpiifort")
setenv("CMAKE_Platform", "hera.intel")

setenv("EPICHOME", "/scratch1/NCEPDEV/nems/role.epic")
setenv("JEDI_INSTALL", pathJoin(os.getenv("EPICHOME"),"contrib"))

whatis("Description: UFS build environment")
