import numpy as np


def sigmoid(x):
    return 1 / (1 + np.exp(-x))    


def identity_function(x):
    return x


class Layer:
    def __init__(self, weight, bias, func):
        self.weight = weight
        self.bias = bias
        self.activation_func = func

    def cal(self, sig):
        result = np.dot(sig, self.weight) + self.bias
        return self.activation_func(result)


def init_network():
    return [
        Layer(
            np.array([[0.1, 0.3, 0.5], [0.2, 0.4, 0.6]]),
            np.array([0.1, 0.2, 0.3]),
            sigmoid
        ),
        Layer(
            np.array([[0.1, 0.4], [0.2, 0.5], [0.3, 0.6]]),
            np.array([0.1, 0.2]),
            sigmoid
        ),
        Layer(
            np.array([[0.1, 0.3], [0.2, 0.4]]),
            np.array([0.1, 0.2]),
            identity_function
        )
    ]


def forward(input_sig, layers):
    sig = input_sig

    for layer in layers:
        sig = layer.cal(sig)

    return sig


network = init_network()
x = np.array([1.0, 0.5])
y = forward(x, network)

print(y) # [ 0.31682708  0.69627909]
