local util = import './util.libsonnet';

util.compile([
  util.echoTask('01'),
  util.echoTask('02'),
])
