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
 
    def test_mae(self):
        data1 = np.array([1.0, -2.0, 3.0])
        data2 = np.array([-2.0, -5.0, 6.0])
        ref = 3.0
        assert comparelib.mae(data1, data2) == ref, "should equal ref=3.0"

if __name__ == '__main__':
    unittest.main() 
