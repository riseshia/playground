local runTaskParams(serviceConfig) = {
  assert (serviceConfig.cpu == null || std.isNumber(serviceConfig.cpu)),
  assert (serviceConfig.memory == null || std.isNumber(serviceConfig.memory)),

  Cluster: serviceConfig.cluster,
  EnableExecuteCommand: true,
  LaunchType: 'FARGATE',
  NetworkConfiguration: {
    AwsvpcConfiguration: {
      SecurityGroups: serviceConfig.securityGroups,
      Subnets: serviceConfig.subnets,
    },
  },
  Overrides: {
    ContainerOverrides: [
      {
        'Command.$': "States.Array('bundle', 'exec', 'rails', $.taskName)",
        Name: 'app',
      },
    ],
    [if std.isNumber(serviceConfig.cpu) then 'Cpu']: serviceConfig.cpu,
    [if std.isNumber(serviceConfig.memory) then 'Memory']: serviceConfig.memory,
  },
  PropagateTags: 'TASK_DEFINITION',
  TaskDefinition: serviceConfig.taskDefinition,
};

{
  runRailsTask(serviceConfig, cpu=null, memory=null, envs=[]): {
    Type: 'Task',
    Resource: 'arn:aws:states:::ecs:runTask.sync',
    Parameters: runTaskParams(serviceConfig {
      cpu: cpu,
      memory: memory,
    }),
    Retry: [
      {
        BackoffRate: 2,
        ErrorEquals: [
          'ECS.AmazonECSException',
        ],
        IntervalSeconds: 5,
        MaxAttempts: 4,
      },
    ],
  },
}
