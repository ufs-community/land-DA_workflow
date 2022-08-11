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

  c. modify the INPUT directory, for an example, use the following directory

     /scratch2/BMC/gsienkf/Tseganeh.Gichamo/stochastic_physics/unit_tests/INPUT

  d. copy the INPUT directory or create a symbolic link

     ln -s /scratch2/BMC/gsienkf/Tseganeh.Gichamo/stochastic_physics/unit_tests/INPUT INPUT

  e. cp input.nml.template input.nml and made the following changes

  f. change lndp_var_list and iseed_lndp (the seed for randomization generator)

  g. n_var_lndp is the actual number of variables in lndp_var_list, change this value according to your choice.

3. map the perturbation pattern in tile format to the vector format

go to the directory vector2tile and run the code to do the mapping

The steps for applying the vectorized perturbation pattern onto land surface variables  

4. compile the code on hera: 

>configure

 choose hera
 
 load the modules indicated
 
>make 

5. To run: 

>cp template.namelist.lndp namelist.lndp

>modify namelist.lndp, the namelist defines the paths of the input/output files, the list of variables to be perturbed, and the perturbation magnitudes

>lndp_apply_pert.exe namelist.lndp
