local util = import './service-sfn-builder.libsonnet';

util.compile([
  util.runRailsTaskWithFork(
    id='00',
    cpu=1024,
    memory=2048,
    TaskName='routes',
    ForkSize=4,
  ),
])
