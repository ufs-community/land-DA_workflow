Code to apply the given perturbation pattern onto vectorized land surface variables.

Zhichang Guo, Mike Barlage, Clara Draper. Aug 2022.

We assume the perturbation pattern has been generated using Phil's stochastic physics and mapped to vector format used by the Noah-MP offline driver from the tile format used by the UFS atmospheric model with the following procedures.

1. git clone the repo of Phil's stochastic physics:

git clone https://github.com/pjpegion/stochastic_physics

2. run Phil's stochastic physics to generate the perturbation pattern:

cd stochastic_physics/unit_tests

modify run_standalone.sh and run the script

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
