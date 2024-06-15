local format = import './some_lib.libsonnet';

local obj = {
  name: format(std.extVar('name')),
  age: 43,
  phones: [
    '+44 1234567',
    '+44 2345678',
  ],
};

obj
