#!/usr/bin/env python
import unittest
import numpy as np
import comparelib as comparelib

class Testcomparelib(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        pass

    @classmethod
    def tearDownClass(cls):
        pass

    # Tests
 
    def test_diff(self):
        data1 = np.array([1.0, -2.0, 3.0])
        data2 = np.array([0.99995, -2.00005, 3.0001])
        comparelib.check_diff(data1, data2, 1e-4, 0.0)

if __name__ == '__main__':
    unittest.main() 
