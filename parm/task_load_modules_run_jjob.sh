#!/bin/bash

set -xue

if [ "$#" -ne 3 ]; then
  echo "Incorrect number of arguments specified:
  Number of arguments specified:  $#

Usage: task_load_modules_run_jjob.sh task_name home_dir machine_name jjob_fn

where the arguments are defined as follows:
  task_name:
  Task name for which this script will load modules and launch the J-job.

  home_dir:
  Full path to the pachage home directory.

  machine_name:
  Machine name in lowercase: e.g. hera/orion"
fi

task_name="$1"
home_dir="$2"
machine_name="$3"

machine="${machine_name,,}"
task_name_upper="${task_name^^}"

module purge

# Source version file for run
ver_fp="${home_dir}/versions/run.ver_${machine}"
if [ -f ${ver_fp} ]; then
  . ${ver_fp}
else
  echo "FATAL ERROR: version file does not exist !!!"
fi
module_dp="${home_dir}/modulefiles/tasks/${machine}"
module use "${module_dp}"

# Load module file for a specific task
task_module_fn="task.${task_name}"
if [ -f "${module_dp}/${task_module_fn}.lua" ]; then
  module load "${task_module_fn}"
  module list
else
  echo "FATAL ERROR: task module file does not exist !!!"
fi

# Load conda env for plotting task
if [ "${task_name}" = "plot_stats" ]; then
  module unload python
  module use ${home_dir}/modulefiles
  module load conda
  set +u
  conda deactivate
  conda activate land_da
  conda list
  set -u
fi

# Run J-job script
${home_dir}/jobs/JLANDDA_${task_name_upper}
