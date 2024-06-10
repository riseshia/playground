local b = import './sfn-builder.libsonnet';

b.merge([
  b.echoTask('01'),
])
