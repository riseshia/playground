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
  StartAt: 'RunTask',
  States: {
    RunTask: util.runRailsTask(serviceConfig) {
      End: true,
    },
    CheckError: {
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
      Type: 'Choice',
    },
    DetermineTaskSize: {
      Choices: [
        {
          IsPresent: true,
          Next: 'SelectLargeSize',
          Variable: '$.params.useLarge',
        },
      ],
      Default: 'SelectDefaultSize',
      Type: 'Choice',
    },
    Fail: {
      Type: 'Fail',
    },
    ProcessErrorInput: {
      Next: 'CheckError',
      Parameters: {
        'Cause.$': 'States.StringToJson($.Cause)',
        'Error.$': '$.Error',
      },
      Type: 'Pass',
    },
    Retry: {
      Next: 'RunTask',
      Seconds: 60,
      Type: 'Wait',
    },
  },
}
