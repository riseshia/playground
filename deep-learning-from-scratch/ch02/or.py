import numpy as np


def OR(x1, x2):
    x = np.array([x1, x2])
    w = np.array([0.5, 0.5])
    b = -0.4

    if np.sum(x * w) + b <= 0:
        return 0
    else:
        return 1

