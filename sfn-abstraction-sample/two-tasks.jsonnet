local util = import './service-util.libsonnet';

util.compile([
  util.runRailsTask(id='01', cpu=1024, memory=2048, TaskName='routes'),
  util.runRailsTask(id='02', cpu=1024, memory=2048, TaskName='routes'),
])
