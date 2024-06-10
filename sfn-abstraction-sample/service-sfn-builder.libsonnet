local builder = import './sfn-builder.libsonnet';

local serviceConfig = {
  cluster: 'service-cluster',
  taskDefinition: 'arn:aws:ecs:ap-northeast-1:xxxx:task-definition/service-batch',
  securityGroups: [
    'sg-ecs-task',
  ],
  subnets: [
    'subnet-private-a',
    'subnet-private-c',
    'subnet-private-d',
  ],
  cpu: 1024,
  memory: 2048,
};

{
  compile(states): builder.compile(states),
  fork(ForkSize, command): builder.fork(ForkSize, command),
  runRailsTask(id, TaskName, cpu=null, memory=null, envs=[]): builder.runRailsTask(
    id=id,
    serviceConfig=serviceConfig,
    TaskName=TaskName,
    cpu=cpu,
    memory=memory,
    envs=envs,
  ),
  runRailsTaskWithFork(id, TaskName, ForkSize, cpu=null, memory=null, envs=[]): builder.runRailsTaskWithFork(
    id=id,
    serviceConfig=serviceConfig,
    TaskName=TaskName,
    ForkSize=ForkSize,
    cpu=cpu,
    memory=memory,
    envs=envs,
  ),
}
