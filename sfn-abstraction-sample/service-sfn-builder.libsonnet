local builder = import './sfn-builder.libsonnet';

local service_config = {
  cluster: 'service-cluster',
  task_definition: 'arn:aws:ecs:ap-northeast-1:xxxx:task-definition/service-batch',
  security_groups: [
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
  merge(states): builder.merge(states),
  fork(fork_size, command): builder.fork(fork_size, command),
  runRailsTask(id, task_name, cpu=null, memory=null, envs=[]): builder.runRailsTask(
    id=id,
    service_config=service_config,
    task_name=task_name,
    cpu=cpu,
    memory=memory,
    envs=envs,
  ),
  runRailsTaskWithFork(id, task_name, fork_size, cpu=null, memory=null, envs=[]): builder.runRailsTaskWithFork(
    id=id,
    service_config=service_config,
    task_name=task_name,
    fork_size=fork_size,
    cpu=cpu,
    memory=memory,
    envs=envs,
  ),
}
