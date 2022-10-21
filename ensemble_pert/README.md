Code to apply the given perturbation pattern onto vectorized land surface variables.

Zhichang Guo, Mike Barlage, Clara Draper. Aug 2022.

We assume the perturbation pattern has been generated using the UFS stochastic physics package and mapped to vector format used by the Noah-MP offline driver from the tile format used by the UFS atmospheric model with the following procedures.

1. git clone the repo of the UFS stochastic physics package:

git clone https://github.com/pjpegion/stochastic_physics

2. run the UFS stochastic physics package to generate the perturbation pattern:

cd stochastic_physics/unit_tests

modify run_standalone.sh and run the script:

  a. modify SBATCH --account to the user account

  b. modify the resolution "RES"

  c. modify the INPUT directory (directory should contain the grid files for that res). An example:

     /scratch2/BMC/gsienkf/Tseganeh.Gichamo/stochastic_physics/unit_tests/INPUT

  d. cp input.nml.template input.nml and made the following changes

  e. change lndp_var_list and iseed_lndp (the seed for randomization generator)

  f. n_var_lndp is the actual number of variables in lndp_var_list, change this value according to your choice.

  g. sbatch run_standalone.sh

This will output (in stochy_out) directory, a number of files, depending on the layout. A layout of 1x1 will give 6 files.

3. map the perturbation pattern in tile format to the vector format

  a. go to vector2tile directory. 

  b. in the namelist (namelist.vector2tile) set 
        direction = "lndp2vector"
        + all variables starting with lndp

  c. run with vector2tile_converter.exe namelist.vector2tile 

The will output a vector the of the perts over land, in the file name specified by lndp_output_file in the namelist.

4. Apply the vectorized perturbation pattern onto land surface variables  
(from this directory)

>cp template.namelist.lndp namelist.lndp

>modify namelist.lndp, the namelist defines the paths of the input/output files, the list of variables to be perturbed, and the perturbation magnitudes

>lndp_apply_pert.exe namelist.lndp

This will output a file with the perturbed parameters. For perturbing veg frac, input file is the static file used by the model.
