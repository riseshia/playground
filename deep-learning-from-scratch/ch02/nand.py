import numpy as np


def NAND(x1, x2):
    x = np.array([x1, x2])
    w = np.array([-0.5, -0.5])
    b = 0.7

    if np.sum(x * w) + b <= 0:
        return 0
    else:
        return 1
