local runTaskParams(service_config, command) = {
  assert (service_config.cpu == null || std.isNumber(service_config.cpu)) : 'cpu must be a number',
  assert (service_config.memory == null || std.isNumber(service_config.memory)) : 'memory must be a number',

  Cluster: service_config.cluster,
  EnableExecuteCommand: true,
  LaunchType: 'FARGATE',
  NetworkConfiguration: {
    AwsvpcConfiguration: {
      SecurityGroups: service_config.security_groups,
      Subnets: service_config.subnets,
    },
  },
  Overrides: {
    ContainerOverrides: [
      {
        Name: 'app',
        Command: command,
        [if std.length(service_config.envs) > 0 then 'Environment']: service_config.envs,
      },
    ],
    [if std.isNumber(service_config.cpu) then 'Cpu']: service_config.cpu,
    [if std.isNumber(service_config.memory) then 'Memory']: service_config.memory,
  },
  PropagateTags: 'TASK_DEFINITION',
  TaskDefinition: service_config.task_definition,
};

local replaceEndToNext(state, nextStateKey) = std.foldl(
  function(newState, attrKey) if attrKey == 'End' then newState { Next: nextStateKey } else newState { [attrKey]: state[attrKey] },
  std.objectFields(state),
  {}
);

local mergeDefinitions(acc, definition) = {
  local nextStateKey = if acc.Idx + 1 < std.length(acc.AllDefinitions) then acc.AllDefinitions[acc.Idx + 1].StartAt else 'Success',

  local states = std.foldl(
    function(newStates, stateKey) if std.objectHas(definition.States[stateKey], 'End') && definition.States[stateKey].End then newStates {
      [stateKey]: replaceEndToNext(definition.States[stateKey], nextStateKey),
    } else newStates {
      [stateKey]: definition.States[stateKey],
    },
    std.objectFields(definition.States),
    {}
  ),

  AllDefinitions: acc.AllDefinitions,
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

local runTaskState(id, service_config, command, cpu=null, memory=null, envs=[]) = {
  ['RunTask%s' % id]: {
    Type: 'Task',
    Resource: 'arn:aws:states:::ecs:runTask.sync',
    Parameters: runTaskParams(service_config {
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
  runRailsTask(id, service_config, task_name, cpu=null, memory=null, envs=[]): {
    local keyWithSuffix = 'RunTask%s' % id,

    StartAt: keyWithSuffix,
    EndAt: keyWithSuffix,
    States: runTaskState(
      id=id,
      service_config=service_config,
      cpu=cpu,
      memory=memory,
      command=['bundle', 'exec', 'rails', task_name],
      envs=envs,
    ) {
      ['RunTask%s' % id]+: {
        End: true,
      },
    },
  },
  runRailsTaskWithFork(service_config, id, task_name, fork_size, cpu=null, memory=null, envs=[]): {
    assert fork_size > 1 : 'fork_size must be greater than 1',

    local task_state = runTaskState(
      id=id,
      service_config=service_config,
      cpu=cpu,
      memory=memory,
      command=['bundle', 'exec', 'rails', task_name],
      envs=envs + [
        { Name: 'BATCH_FORK_COUNT', Value: std.toString(fork_size) },
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
    local task_definition = {
      StartAt: 'RunTask%s' % id,
      EndAt: 'RunTask%s' % id,
      States: task_state,
    },

    StartAt: 'GenNumbers',
    States: {
      GenNumbers: {
        Type: 'Pass',
        Next: 'ForkProcess',
        Parameters: {
          'ForkNumbers.$': 'States.ArrayRange(0, %s, 1)' % (fork_size - 1),
          ForkSize: std.toString(fork_size),
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
          StartAt: task_definition.StartAt,
          States: task_definition.States {
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
  merge(definitions): {
    assert std.length(definitions) > 0 : 'definitions must not be empty',

    StartAt: definitions[0].StartAt,
    States: std.foldl(mergeDefinitions, definitions, { AllDefinitions: definitions, Idx: 0, Result: {} }).Result + terminateStates,
  },
}
