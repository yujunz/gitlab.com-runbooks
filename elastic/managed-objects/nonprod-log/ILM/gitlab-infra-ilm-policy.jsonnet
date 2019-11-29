{
  policy: {
    phases: {
      hot: {
        actions: {
          rollover: {
            max_age: '3d',
            max_size: '50gb',
          },
          set_priority: {
            priority: 100,
          },
        },
      },
      warm: {
        min_age: '1m',
        actions: {
          forcemerge: {
            max_num_segments: 1,
          },
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
        min_age: '7d',
        actions: {
          delete: {},
        },
      },
    },
  },
}