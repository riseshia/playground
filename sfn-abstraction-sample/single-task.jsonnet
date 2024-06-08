local util = import './service-util.libsonnet';

util.compile([
  util.runRailsTask(cpu=1024, memory=2048, TaskName='routes'),
])
