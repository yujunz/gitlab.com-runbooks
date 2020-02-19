{
  policy: {
    phases: {
      hot: {
        actions: {
          rollover: {
            max_age: '3d',
            max_size: '10gb',
          },
          set_priority: {
            priority: 100,
          },
        },
      },
      warm: {
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
        min_age: '120d',
        actions: {
          delete: {},
        },
      },
    },
  },
}