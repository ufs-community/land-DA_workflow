#!/usr/bin/env python
import numpy as np

# python function ro find mean absolute difference between two datasets
def mae(data1, data2):
    # first calculate difference
    diff = data2 - data1
    # calculate mean absolute difference
    diff = np.nanmean(np.abs(diff))
    return diff
