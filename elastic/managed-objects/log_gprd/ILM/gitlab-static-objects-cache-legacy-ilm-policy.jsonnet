{
  // this is a legacy policy for the old (non-ILM managed) indices
  // the new policy performs rollover.
  policy: {
    phases: {
      delete: {
        min_age: '30d',  // keep static-objects-cache logs for 30d
        actions: {
          delete: {},
        },
      },
    },
  },
}
