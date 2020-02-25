// These values are used in several places, so best to DRY them up
{
  slos: {
    urgent: {
      queueingDurationSeconds: 10,
      executionDurationSeconds: 10,
    },
    nonUrgent: {
      queueingDurationSeconds: 60,
      executionDurationSeconds: 300,
    },
  },
}
