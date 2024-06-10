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
        Name: 'app',
        Command: command,
        [if std.length(serviceConfig.envs) > 0 then 'Environment']: serviceConfig.envs,
      },
    ],
    [if std.isNumber(serviceConfig.cpu) then 'Cpu']: serviceConfig.cpu,
    [if std.isNumber(serviceConfig.memory) then 'Memory']: serviceConfig.memory,
  },
  PropagateTags: 'TASK_DEFINITION',
  TaskDefinition: serviceConfig.taskDefinition,
};

local replaceEndToNext(state, nextStateKey) = std.foldl(
  function(newState, attrKey) if attrKey == 'End' then newState { Next: nextStateKey } else newState { [attrKey]: state[attrKey] },
  std.objectFields(state),
  {}
);

local compileCommands(acc, command) = {
  local nextStateKey = if acc.Idx + 1 < std.length(acc.AllCommands) then acc.AllCommands[acc.Idx + 1].StartAt else 'Success',

  local states = std.foldl(
    function(newStates, stateKey) if std.objectHas(command.States[stateKey], 'End') && command.States[stateKey].End then newStates {
      [stateKey]: replaceEndToNext(command.States[stateKey], nextStateKey),
    } else newStates {
      [stateKey]: command.States[stateKey],
    },
    std.objectFields(command.States),
    {}
  ),

  AllCommands: acc.AllCommands,
  Idx: acc.Idx + 1,
  Result: acc.Result + states,
};

local terminateStates = {
  Success: {
    Type: 'Pass',
    End: true,
  },
  Fail: {
    Type: 'Fail',
  },
};

local runTaskState(id, serviceConfig, command, cpu=null, memory=null, envs=[]) = {
  ['RunTask%s' % id]: {
    Type: 'Task',
    Resource: 'arn:aws:states:::ecs:runTask.sync',
    Parameters: runTaskParams(serviceConfig {
      cpu: cpu,
      memory: memory,
      envs: envs,
    }, command),
    ResultPath: '$.TaskResult',
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
        Next: 'ProcessErrorInput%s' % id,
      },
    ],
  },
  ['ProcessErrorInput%s' % id]: {
    Type: 'Pass',
    Next: 'CheckError%s' % id,
    Parameters: {
      'Cause.$': 'States.StringToJson($.TaskResult.Cause)',
      'Error.$': '$.TaskResult.Error',
    },
  },
  ['CheckError%s' % id]: {
    Type: 'Choice',
    Choices: [
      {
        Next: 'Retry%s' % id,
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
  ['Retry%s' % id]: {
    Type: 'Wait',
    Next: 'RunTask%s' % id,
    Seconds: 60,
  },
};

{
  runRailsTask(id, serviceConfig, TaskName, cpu=null, memory=null, envs=[]): {
    local keyWithSuffix = 'RunTask%s' % id,

    StartAt: keyWithSuffix,
    EndAt: keyWithSuffix,
    States: runTaskState(
      id=id,
      serviceConfig=serviceConfig,
      cpu=cpu,
      memory=memory,
      command=['bundle', 'exec', 'rails', TaskName],
      envs=envs,
    ) {
      ['RunTask%s' % id]+: {
        End: true,
      },
    },
  },
  runRailsTaskWithFork(serviceConfig, id, TaskName, ForkSize, cpu=null, memory=null, envs=[]): {
    assert ForkSize > 1 : 'ForkSize must be greater than 1',

    local taskState = runTaskState(
      id=id,
      serviceConfig=serviceConfig,
      cpu=cpu,
      memory=memory,
      command=['bundle', 'exec', 'rails', TaskName],
      envs=envs + [
        { Name: 'BATCH_FORK_COUNT', Value: std.toString(ForkSize) },
        { Name: 'BATCH_FORK_NUMBER', 'Value.$': "States.Format('{}', $.ForkNumber)" },
      ],
    ) {
      ['RunTask%s' % id]+: {
        Next: 'MarkingSuccess%s' % id,
      },
      ['ProcessErrorInput%s' % id]+: {
        Parameters+: {
          'ForkNumber.$': '$.ForkNumber',
          'ForkSize.$': '$.ForkSize',
        },
      },
      ['CheckError%s' % id]+: {
        Default: 'MarkingFailure%s' % id,
      },
    },
    local taskCommand = {
      StartAt: 'RunTask%s' % id,
      EndAt: 'RunTask%s' % id,
      States: taskState,
    },

    StartAt: 'GenNumbers',
    States: {
      GenNumbers: {
        Type: 'Pass',
        Next: 'ForkProcess',
        Parameters: {
          'ForkNumbers.$': 'States.ArrayRange(0, %s, 1)' % (ForkSize - 1),
          ForkSize: std.toString(ForkSize),
        },
      },
      ForkProcess: {
        Type: 'Map',
        Next: 'FindFailedMap',
        ItemSelector: {
          'ForkNumber.$': '$$.Map.Item.Value',
          'ForkSize.$': '$.ForkSize',
        },
        ItemsPath: '$.ForkNumbers',
        ItemProcessor: {
          ProcessorConfig: {
            Mode: 'INLINE',
          },
          StartAt: taskCommand.StartAt,
          States: taskCommand.States {
            ['MarkingSuccess%s' % id]: {
              End: true,
              Result: 'Success',
              Type: 'Pass',
            },
            ['MarkingFailure%s' % id]: {
              End: true,
              Result: 'Failure',
              Type: 'Pass',
            },
          },
        },
      },
      FindFailedMap: {
        Next: 'FinalJudge',
        Parameters: {
          'HasFailure.$': "States.ArrayContains($, 'Failure')",
        },
        Type: 'Pass',
      },
      FinalJudge: {
        Choices: [
          {
            BooleanEquals: true,
            Next: 'SfnFailed',
            Variable: '$.HasFailure',
          },
        ],
        Default: 'SfnSucceed',
        Type: 'Choice',
      },
    },
    EndAt: 'SfnSucceed',
  },
  echoTask(suffix): {
    local keyWithSuffix = 'RunTask%s' % suffix,

    StartAt: keyWithSuffix,
    States: {
      [keyWithSuffix]: {
        Type: 'Pass',
        End: true,
      },
    },
    EndAt: keyWithSuffix,
  },
  compile(commands): {
    assert std.length(commands) > 0 : 'commands must not be empty',

    StartAt: commands[0].StartAt,
    States: std.foldl(compileCommands, commands, { AllCommands: commands, Idx: 0, Result: {} }).Result + terminateStates,
  },
}
