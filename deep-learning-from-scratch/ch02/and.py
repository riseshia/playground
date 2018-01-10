def AND(x, y):
    w1, w2, theta = 0.5, 0.5, 0.7

    if theta <= x * w1 + y * w2:
        return 1
    else:
        return 0
