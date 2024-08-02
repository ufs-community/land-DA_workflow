#!/usr/bin/env python
import sys
import numpy as np
from netCDF4 import Dataset

with Dataset(sys.argv[1]) as nc1, Dataset(sys.argv[2]) as nc2:
  f = open(sys.argv[4], "a")
  # Check if the list of variables are the same
  if nc1.variables.keys()!=nc2.variables.keys():
    print("FATAL ERROR: list of variables are different")
    f.write("FATAL ERROR: list of variables are different.\n")
    sys.exit(2)

  for varname in nc1.variables.keys():
    # First check if each variable has the same dimension
    if np.shape(nc1[varname][:])!=np.shape(nc2[varname][:]):
      print(varname,"FATAL ERROR: dimension is different")
      f.write("FATAL ERROR: dimension is different.\n")
      sys.exit(2)
    # If dimension is the same, compare data
    else:
      np.testing.assert_allclose(nc1[varname][:], nc2[varname][:], rtol=1e-8, atol=float(sys.argv[3]))

  f.write("{} :: {} :: {} :: TEST was complete successfully.\n".format(sys.argv[6],sys.argv[5],sys.argv[7]))
  f.close()
