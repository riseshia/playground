local b = import './service-sfn-builder.libsonnet';

b.merge([
  b.runRailsTask(id='01', cpu=1024, memory=2048, TaskName='routes'),
])
