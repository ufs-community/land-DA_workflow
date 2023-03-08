#!/usr/bin/env python
import numpy as np

# python function check difference between two datasets
def check_diff(data1, data2, rtol_, atol_):
    #
    np.testing.assert_allclose(data1, data2, rtol=rtol_, atol=atol_)
