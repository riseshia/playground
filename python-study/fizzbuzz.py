def fizzbuzz(n):
    if n % 15 == 0:
        return "FizzBuzz"
    elif n % 3 == 0:
        return "Fizz"
    elif n % 5 == 0:
        return "Buzz"
    else:
        return str(n)


# TEST
def assert_equal(expected, actual, message=""):
    if expected == actual:
        print(".", end="")
    else:
        print("'{expected}' is expected, but '{actual}' is returned"
              .format(expected=expected, actual=actual))

assert_equal("1", fizzbuzz(1))
assert_equal("Fizz", fizzbuzz(3))
assert_equal("Buzz", fizzbuzz(5))
assert_equal("FizzBuzz", fizzbuzz(15))
print()

# Run

n = input("Type n:")
filename = input("Type filename you want to save fizzbuzz:")

f = open("./{filename}".format(filename=filename), "w")
for num in range(1, int(n)+1):
    f.write("{fizzbuzz}\n".format(fizzbuzz=fizzbuzz(num)))
f.close()
print("Save is completed!")
