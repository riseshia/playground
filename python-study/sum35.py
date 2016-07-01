# TEST SETUP
def assert_equal(expected, actual, message=""):
    if expected == actual:
        print(".", end="")
    else:
        print("'{expected}' is expected, but '{actual}' is returned"
              .format(expected=expected, actual=actual))

# 3+6+9+...+n
# (1+2+3+...+(n//3))*3
# (n//3) * ((n//3) + 1) / 2 * 3
def cal(n, target_num):
    limit = n - 1
    x = limit // target_num
    return x * (x + 1) // 2 * target_num

def sum35(last):
    return cal(last, 3) + cal(last, 5) - cal(last, 15)

assert_equal(23, sum35(10))
assert_equal(18, cal(10, 3))
assert_equal(5, cal(10, 5))
print(sum35(10000))
