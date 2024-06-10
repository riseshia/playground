local b = import './service-sfn-builder.libsonnet';

b.merge([
  b.runRailsTask(id='00', cpu=1024, memory=2048, TaskName='routes'),
  b.runRailsTaskWithFork(
    id='01',
    cpu=1024,
    memory=2048,
    TaskName='routes',
    ForkSize=4,
  ),
  b.runRailsTask(id='02', cpu=1024, memory=2048, TaskName='routes'),
])
