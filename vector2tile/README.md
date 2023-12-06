Code to map between vector format used by the Noah-MP offline driver, and the tile format used by the UFS atmospheric model. Currently used to prepare input tile files for JEDI. These files include only those fields required by JEDI, rather than the full restart. Can also be used to map stochastic_physics output to the tile or vector. Stochastic physics output files depend on the layout, with 1x1 layout giving one file per tile.

Mike Barlage, Clara Draper. Dec 2021.

To compile on hera: 

>configure

 choose hera
 
 load the modules indicated
 
>make 

To run: 

>vector2tile_converter.exe namelist.vector2tile

the namelist defines the conversion direction and the paths of the files

Details: 

the vector2tile pathway assumes that the vector file exists in the vector_restart_path directory and overwrites/creates tile files in the output_path

the tile2vector pathway is a little tricky, it assumes the tile files exist in tile_restart_path and overwrites only the snow variables in the vector file in the output_path. If the vector file does not exist in output_path the process will fail.  

the overall assumption here is that we will have a full model vector restart file, then convert the vector to tiles for only snow variables, then convert the updated snow variables back to the full vector restart file

For the lndp2vector or lndp2tile option, a new file will be created with the pertbations and lat lon only.

