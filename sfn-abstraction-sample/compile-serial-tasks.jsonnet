local util = import './sfn-builder.libsonnet';

util.compile([
  util.echoTask('01'),
  util.echoTask('02'),
])
