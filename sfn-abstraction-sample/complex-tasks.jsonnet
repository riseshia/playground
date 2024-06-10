local util = import './service-sfn-builder.libsonnet';

util.compile([
  util.runRailsTask(id='00', cpu=1024, memory=2048, TaskName='routes'),
  util.runRailsTaskWithFork(
    id='01',
    cpu=1024,
    memory=2048,
    TaskName='routes',
    ForkSize=4,
  ),
  util.runRailsTask(id='02', cpu=1024, memory=2048, TaskName='routes'),
])
