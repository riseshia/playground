local b = import './sfn-builder.libsonnet';

b.compile([
  b.echoTask('01'),
  b.echoTask('02'),
])
