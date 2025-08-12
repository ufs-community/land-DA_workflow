prepend_path("MODULEPATH", os.getenv("modulepath_modulefiles"))

load(pathJoin("stack-oneapi", stack_oneapi_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_intel_oneapi_mpi_ver))
load(pathJoin("intel-oneapi-mkl", intel_oneapi_mkl_ver))
load(pathJoin("prod_util", prod_util_ver))

prepend_path("MODULEPATH", os.getenv("modulepath_pymodule"))

load("python-ufs-land-da-wflow")
