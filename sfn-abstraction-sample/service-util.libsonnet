local util = import './util.libsonnet';

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
  runRailsTask(TaskName, cpu=null, memory=null, envs=[]): util.runRailsTask(
    serviceConfig=serviceConfig,
    TaskName=TaskName,
    cpu=cpu,
    memory=memory,
    envs=envs,
  ),
  compile(states): util.compile(states),
}
