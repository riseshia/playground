local b = import './service-sfn-builder.libsonnet';

b.merge([
  b.runRailsTaskWithFork(
    id='00',
    cpu=1024,
    memory=2048,
    TaskName='routes',
    ForkSize=4,
  ),
])
