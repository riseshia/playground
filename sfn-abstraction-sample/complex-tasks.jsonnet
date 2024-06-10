local b = import './service-sfn-builder.libsonnet';

b.merge([
  b.runRailsTask(id='00', cpu=1024, memory=2048, task_name='routes'),
  b.runRailsTaskWithFork(
    id='01',
    cpu=1024,
    memory=2048,
    task_name='routes',
    fork_size=4,
  ),
  b.runRailsTask(id='02', cpu=1024, memory=2048, task_name='routes'),
])
