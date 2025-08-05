help([[
loads modules necessary for building the land-DA workflow on Hera using Intel
]])

whatis([===[Loads modules necessary for building the land-DA workflow on Hera]===])

prepend_path("MODULEPATH", os.getenv("modulepath_modulefiles"))
prepend_path("MODULEPATH", os.getenv("modulepath_spack_stack"))

load(pathJoin("stack-oneapi", stack_intel_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_intel_oneapi_mpi_ver))

load(pathJoin("cmake", cmake_ver))
load(pathJoin("ecbuild", ecbuild_ver))

load(pathJoin("jasper", jasper_ver))
load(pathJoin("zlib", zlib_ver))
load(pathJoin("libpng", libpng_ver))
load(pathJoin("hdf5", hdf5_ver))
load(pathJoin("netcdf-c", netcdf_c_ver))
load(pathJoin("netcdf-fortran", netcdf_fortran_ver))
load(pathJoin("parallelio", parallelio_ver))
load(pathJoin("esmf", esmf_ver))
load(pathJoin("fms",fms_ver))
load(pathJoin("bacio", bacio_ver))
load(pathJoin("g2", g2_ver))
load(pathJoin("g2tmpl", g2tmpl_ver))
load(pathJoin("ip", ip_ver))
load(pathJoin("sp", sp_ver))
load(pathJoin("w3emc", w3emc_ver))
load(pathJoin("gftl-shared", gftl_shared_ver))
load(pathJoin("mapl", mapl_ver))
load(pathJoin("scotch", scotch_ver))

load(pathJoin("nemsio", nemsio_ver))
load(pathJoin("sfcio", sfcio_ver))
load(pathJoin("sigio", sigio_ver))
load(pathJoin("nccmp", nccmp_ver))

load(pathJoin("prod_util", prod_util_ver))

load("crtm/2.4.0.1")

setenv("CC", "mpiicx")
setenv("CXX", "mpiicpx")
setenv("FC", "mpiifort")
setenv("I_MPI_CC", "icx")
setenv("I_MPI_CXX", "icpx")
setenv("I_MPI_F90", "ifort")

setenv("CMAKE_Platform", "hera.intel")

