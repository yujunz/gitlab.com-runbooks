{
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
