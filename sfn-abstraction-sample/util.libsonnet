local runTaskParams(serviceConfig, command) = {
  assert (serviceConfig.cpu == null || std.isNumber(serviceConfig.cpu)) : 'cpu must be a number',
  assert (serviceConfig.memory == null || std.isNumber(serviceConfig.memory)) : 'memory must be a number',

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
        Command: command,
        Name: 'app',
      },
    ],
    [if std.isNumber(serviceConfig.cpu) then 'Cpu']: serviceConfig.cpu,
    [if std.isNumber(serviceConfig.memory) then 'Memory']: serviceConfig.memory,
  },
  PropagateTags: 'TASK_DEFINITION',
  TaskDefinition: serviceConfig.taskDefinition,
};

local compileStates(acc, state) =
  acc {
    [state.Name]: state.State,
  } + state.SubStates;

local terminateStates = {
  Success: {
    Type: 'Pass',
    End: true,
  },
  Fail: {
    Type: 'Fail',
  },
};

local runTaskState(serviceConfig, command, cpu=null, memory=null, envs=[]) = {
  Type: 'Task',
  Resource: 'arn:aws:states:::ecs:runTask.sync',
  Parameters: runTaskParams(serviceConfig {
    cpu: cpu,
    memory: memory,
  }, command),
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
  Catch: [
    {
      ErrorEquals: [
        'States.ALL',
      ],
      Next: 'ProcessErrorInput',
    },
  ],
  Next: 'Success',
};

{
  runRailsTask(serviceConfig, TaskName, cpu=null, memory=null, envs=[]): {
    Name: 'RunTask',
    State: runTaskState(
      serviceConfig=serviceConfig,
      cpu=cpu,
      memory=memory,
      command=['bundle', 'exec', 'rails', TaskName],
    ),
    SubStates: {
      ProcessErrorInput: {
        Type: 'Pass',
        Next: 'CheckError',
        Parameters: {
          'Cause.$': 'States.StringToJson($.Cause)',
          'Error.$': '$.Error',
        },
      },
      CheckError: {
        Type: 'Choice',
        Choices: [
          {
            Next: 'Retry',
            Or: [
              {
                StringEquals: 'ResourceInitializationError: failed to configure ENI: failed to setup regular eni: netplugin failed with no error message',
                Variable: '$.Cause.StoppedReason',
              },
              {
                StringEquals: 'Unexpected EC2 error while attempting to attach network interface to instance',
                Variable: '$.Cause.StoppedReason',
              },
            ],
          },
        ],
        Default: 'Fail',
      },
      Retry: {
        Type: 'Wait',
        Next: 'RunTask',
        Seconds: 60,
      },
    },
  },
  compile(states): {
    assert std.length(states) > 0 : 'states must not be empty',

    StartAt: states[0].Name,
    States: std.foldl(compileStates, states, {}) + terminateStates,
  },
}
