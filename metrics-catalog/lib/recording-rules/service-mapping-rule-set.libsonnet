{
  // The Servuce Mapping ruleset is used to generate a series of
  // static recording rules which are used in alert evaluation
  serviceMappingRuleSet()::
    {
      // Generates the recording rules given a service definition
      generateRecordingRulesForService(serviceDefinition)::
        (
          // Disable ops-rate-prediction and anomaly detection.
          // This should be used on services with non-normal distributions
          // of their ops rate metrics
          if ({ disableOpsRatePrediction: false } + serviceDefinition).disableOpsRatePrediction then
            [
              {
                record: 'gitlab_service:mapping:disable_ops_rate_prediction',
                labels: {
                  type: serviceDefinition.type,
                  tier: serviceDefinition.tier,
                },
                expr: '1',
              },
            ]
          else
            []
        ),

    },

}
