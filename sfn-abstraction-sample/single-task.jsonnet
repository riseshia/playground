local util = import './service-sfn-builder.libsonnet';

util.compile([
  util.runRailsTask(id='01', cpu=1024, memory=2048, TaskName='routes'),
])
