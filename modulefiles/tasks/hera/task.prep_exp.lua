prepend_path("MODULEPATH", os.getenv("modulepath_spack_stack"))
prepend_path("MODULEPATH", os.getenv("modulepath_spack_stack_jedi"))

load(pathJoin("stack-intel", stack_intel_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_impi_ver))
load(pathJoin("stack-python", stack_python_ver))

load(pathJoin("prod_util", prod_util_ver))
