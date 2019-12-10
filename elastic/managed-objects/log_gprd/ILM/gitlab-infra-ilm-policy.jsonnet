{
  policy: {
    phases: {
      hot: {
        actions: {
          rollover: {
            max_age: '3d',
            max_size: '40gb',
          },
          set_priority: {
            priority: 100,
          },
        },
      },
      warm: {
        // if no criteria are set here, the move to warm will happen on rollover
        // min_age: '1h',  // min value is 1h, if you set below that, the cluster will default to 1d
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
        min_age: '7d',  //7d after documents are received by the cluster, not from the log timestamp
        actions: {
          delete: {},
        },
      },
    },
  },
}
