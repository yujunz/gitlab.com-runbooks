{
  policy: {
    phases: {
      hot: {
        actions: {
          rollover: {
            max_age: '7d',  // try to pack a few days worth per index
            max_size: '20gb',
          },
          set_priority: {
            priority: 100,
          },
        },
      },
      warm: {
        min_age: '1d',
        actions: {
          allocate: {
            require: {
              data: 'warm',
            },
          },
          set_priority: {
            priority: 50,
          },
        },
      },
      delete: {
        min_age: '30d',  // keep static-objects-cache logs for 30d
        actions: {
          delete: {},
        },
      },
    },
  },
}
