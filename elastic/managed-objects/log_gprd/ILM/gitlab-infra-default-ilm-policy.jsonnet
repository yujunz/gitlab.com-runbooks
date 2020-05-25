{
  policy: {
    phases: {
      hot: {
        actions: {
          rollover: {
            max_age: '24h',
            max_size: '20gb',
          },
          set_priority: {
            priority: 100,
          },
        },
      },
      warm: {
        // if no criteria are set here, the move to warm will happen on rollover
        min_age: '2d',  // min value is 1h, if you set below that, the cluster will default to 1d
        actions: {
          // skipping force merge for now for a performance optimisation test
          // forcemerge: {
          //   max_num_segments: 1,
          // },
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
        min_age: '7d',  //7d after rollover
        actions: {
          delete: {},
        },
      },
    },
  },
}
