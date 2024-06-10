local b = import './sfn-builder.libsonnet';

b.merge([
  b.echoTask('01'),
  b.echoTask('02'),
])
