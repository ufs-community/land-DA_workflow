help([[
  This module loads libraries required for building UFS Land-DA Workflow
  on the NOAA RDHPCS machine Gaea C6 using Intel
]])
whatis([===[Loads libraries needed for building the UFS Land-DA Workflow on Gaea C6]===])

prepend_path("MODULEPATH", "/ncrc/proj/epic/spack-stack/c6/spack-stack-1.9.2/envs/ue-intel-2023.2.0/install/modulefiles/Core")
prepend_path("MODULEPATH", "/ncrc/proj/epic/spack-stack/c6/modulefiles")

stack_intel_ver=os.getenv("stack_intel_ver") or "2023.2.0"
load(pathJoin("stack-intel", stack_intel_ver))

stack_cray_mpich_ver=os.getenv("stack_cray_mpich_ver") or "8.1.30"
load(pathJoin("stack-cray-mpich", stack_cray_mpich_ver))

stack_python_ver=os.getenv("stack_python_ver") or "3.11.7"
load(pathJoin("stack-python", stack_python_ver))

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

zlib_ver=os.getenv("zlib_ver") or "1.2.13"
load(pathJoin("zlib", zlib_ver))

load("crtm/2.4.0.1")

unload("darshan-runtime")
unload("cray-libsci")

setenv("CC","cc")
setenv("CXX","CC")
setenv("FC","ftn")
setenv("CMAKE_Platform","gaeac6.intel")
