{
  dynamic: 'false',
  properties: {
    '@timestamp': {
      type: 'date',
    },
    attributes: {
      properties: {
        logging: {
          properties: {
            googleapis: {
              properties: {
                'com/timestamp': {
                  type: 'date',
                },
              },
            },
          },
        },
      },
    },
    ecs: {
      properties: {
        version: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
      },
    },
    host: {
      properties: {
        name: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
      },
    },
    json: {
      properties: {
        insertId: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        jsonPayload: {
          properties: {
            MESSAGE: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            PRIORITY: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            SYSLOG_FACILITY: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            SYSLOG_IDENTIFIER: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            _BOOT_ID: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            _CAP_EFFECTIVE: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            _CMDLINE: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            _COMM: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            _EXE: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            _GID: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            _HOSTNAME: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            _MACHINE_ID: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            _PID: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            _STREAM_ID: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            _SYSTEMD_CGROUP: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            _SYSTEMD_INVOCATION_ID: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            _SYSTEMD_SLICE: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            _SYSTEMD_UNIT: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            _TRANSPORT: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            _UID: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            apiVersion: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            involvedObject: {
              properties: {
                apiVersion: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                kind: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                name: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                namespace: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                resourceVersion: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                uid: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
              },
            },
            kind: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            message: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            metadata: {
              properties: {
                creationTimestamp: {
                  type: 'date',
                },
                name: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                namespace: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                resourceVersion: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                selfLink: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                uid: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
              },
            },
            reason: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            source: {
              properties: {
                component: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
              },
            },
            type: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
          },
        },
        labels: {
          properties: {
            authorization: {
              properties: {
                k8s: {
                  properties: {
                    'io/decision': {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    'io/reason': {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                  },
                },
              },
            },
            gke: {
              properties: {
                googleapis: {
                  properties: {
                    'com/log_type': {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
        logName: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        operation: {
          properties: {
            first: {
              type: 'boolean',
            },
            id: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            last: {
              type: 'boolean',
            },
            producer: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
          },
        },
        protoPayload: {
          properties: {
            '@type': {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            authenticationInfo: {
              properties: {
                principalEmail: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
              },
            },
            authorizationInfo: {
              properties: {
                granted: {
                  type: 'boolean',
                },
                permission: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                resource: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
              },
            },
            methodName: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            request: {
              properties: {
                '@type': {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                apiVersion: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                kind: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                metadata: {
                  properties: {
                    annotations: {
                      properties: {
                        app: {
                          properties: {
                            gitlab: {
                              properties: {
                                'com/app': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'com/env': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                        'control-plane': {
                          properties: {
                            alpha: {
                              properties: {
                                kubernetes: {
                                  properties: {
                                    'io/leader': {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                        deployment: {
                          properties: {
                            kubernetes: {
                              properties: {
                                'io/desired-replicas': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'io/max-replicas': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'io/revision': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                      },
                    },
                    creationTimestamp: {
                      type: 'date',
                    },
                    generation: {
                      type: 'long',
                    },
                    labels: {
                      properties: {
                        app: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        'pod-template-hash': {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        'queue-pod-name': {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        release: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        shard: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        stage: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        tier: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        type: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                      },
                    },
                    name: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    namespace: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    ownerReferences: {
                      properties: {
                        apiVersion: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        blockOwnerDeletion: {
                          type: 'boolean',
                        },
                        controller: {
                          type: 'boolean',
                        },
                        kind: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        name: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        uid: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                      },
                    },
                    resourceVersion: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    selfLink: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    uid: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                  },
                },
                spec: {
                  properties: {
                    hostIPC: {
                      type: 'boolean',
                    },
                    hostPID: {
                      type: 'boolean',
                    },
                    privileged: {
                      type: 'boolean',
                    },
                    readOnlyRootFilesystem: {
                      type: 'boolean',
                    },
                    replicas: {
                      type: 'long',
                    },
                    selector: {
                      properties: {
                        matchLabels: {
                          properties: {
                            app: {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                            'pod-template-hash': {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                            'queue-pod-name': {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                            release: {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                          },
                        },
                      },
                    },
                    template: {
                      properties: {
                        metadata: {
                          properties: {
                            annotations: {
                              properties: {
                                'checksum/configmap': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'checksum/configmap-pod': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'cluster-autoscaler': {
                                  properties: {
                                    kubernetes: {
                                      properties: {
                                        'io/safe-to-evict': {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                      },
                                    },
                                  },
                                },
                                gitlab: {
                                  properties: {
                                    'com/prometheus_port': {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                    'com/prometheus_scrape': {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                  },
                                },
                                prometheus: {
                                  properties: {
                                    'io/port': {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                    'io/scrape': {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                  },
                                },
                              },
                            },
                            labels: {
                              properties: {
                                app: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'pod-template-hash': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'queue-pod-name': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                release: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                shard: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                stage: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                tier: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                type: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                      },
                    },
                    validation: {
                      properties: {
                        openAPIV3Schema: {
                          properties: {
                            properties: {
                              properties: {
                                spec: {
                                  type: 'object',
                                },
                              },
                            },
                          },
                        },
                      },
                    },
                  },
                },
                status: {
                  properties: {
                    availableReplicas: {
                      type: 'long',
                    },
                    fullyLabeledReplicas: {
                      type: 'long',
                    },
                    observedGeneration: {
                      type: 'long',
                    },
                    readyReplicas: {
                      type: 'long',
                    },
                    replicas: {
                      type: 'long',
                    },
                  },
                },
                subjects: {
                  properties: {
                    kind: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    name: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    namespace: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                  },
                },
              },
            },
            requestMetadata: {
              properties: {
                callerIp: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                callerNetwork: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                callerSuppliedUserAgent: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                destinationAttributes: {
                  type: 'object',
                },
                requestAttributes: {
                  type: 'object',
                },
              },
            },
            resourceName: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            response: {
              properties: {
                '@type': {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                apiVersion: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                kind: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                metadata: {
                  properties: {
                    annotations: {
                      properties: {
                        app: {
                          properties: {
                            gitlab: {
                              properties: {
                                'com/app': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'com/env': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                        apparmor: {
                          properties: {
                            security: {
                              properties: {
                                beta: {
                                  properties: {
                                    kubernetes: {
                                      properties: {
                                        'io/allowedProfileNames': {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                        'io/defaultProfileName': {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                      },
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                        components: {
                          properties: {
                            gke: {
                              properties: {
                                'io/component-name': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'io/component-version': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                        'control-plane': {
                          properties: {
                            alpha: {
                              properties: {
                                kubernetes: {
                                  properties: {
                                    'io/leader': {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                        deployment: {
                          properties: {
                            kubernetes: {
                              properties: {
                                'io/desired-replicas': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'io/max-replicas': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'io/revision': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                        deprecated: {
                          properties: {
                            daemonset: {
                              properties: {
                                template: {
                                  properties: {
                                    generation: {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                        kubectl: {
                          properties: {
                            kubernetes: {
                              properties: {
                                'io/last-applied-configuration': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                        kubernetes: {
                          properties: {
                            'io/description': {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                          },
                        },
                        seccomp: {
                          properties: {
                            security: {
                              properties: {
                                alpha: {
                                  properties: {
                                    kubernetes: {
                                      properties: {
                                        'io/allowedProfileNames': {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                        'io/defaultProfileName': {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                      },
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                      },
                    },
                    creationTimestamp: {
                      type: 'date',
                    },
                    generation: {
                      type: 'long',
                    },
                    labels: {
                      properties: {
                        addonmanager: {
                          properties: {
                            kubernetes: {
                              properties: {
                                'io/mode': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                        app: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        'k8s-app': {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        kubernetes: {
                          properties: {
                            'io/cluster-service': {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                          },
                        },
                        'pod-template-hash': {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        'queue-pod-name': {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        release: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        shard: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        stage: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        tier: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        type: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                      },
                    },
                    name: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    namespace: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    ownerReferences: {
                      properties: {
                        apiVersion: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        blockOwnerDeletion: {
                          type: 'boolean',
                        },
                        controller: {
                          type: 'boolean',
                        },
                        kind: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        name: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        uid: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                      },
                    },
                    resourceVersion: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    selfLink: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    uid: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                  },
                },
                roleRef: {
                  properties: {
                    apiGroup: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    kind: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    name: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                  },
                },
                spec: {
                  properties: {
                    allowPrivilegeEscalation: {
                      type: 'boolean',
                    },
                    allowedHostPaths: {
                      properties: {
                        pathPrefix: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                      },
                    },
                    conversion: {
                      properties: {
                        strategy: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                      },
                    },
                    fsGroup: {
                      properties: {
                        rule: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                      },
                    },
                    group: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    hostNetwork: {
                      type: 'boolean',
                    },
                    names: {
                      properties: {
                        kind: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        listKind: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        plural: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        shortNames: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        singular: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                      },
                    },
                    preserveUnknownFields: {
                      type: 'boolean',
                    },
                    replicas: {
                      type: 'long',
                    },
                    revisionHistoryLimit: {
                      type: 'long',
                    },
                    runAsUser: {
                      properties: {
                        rule: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                      },
                    },
                    scope: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    seLinux: {
                      properties: {
                        rule: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                      },
                    },
                    selector: {
                      properties: {
                        matchLabels: {
                          properties: {
                            app: {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                            'k8s-app': {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                            'pod-template-hash': {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                            'queue-pod-name': {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                            release: {
                              type: 'text',
                              fields: {
                                keyword: {
                                  type: 'keyword',
                                  ignore_above: 256,
                                },
                              },
                            },
                          },
                        },
                      },
                    },
                    supplementalGroups: {
                      properties: {
                        rule: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                      },
                    },
                    template: {
                      properties: {
                        metadata: {
                          properties: {
                            annotations: {
                              properties: {
                                'checksum/configmap': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'checksum/configmap-pod': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'cluster-autoscaler': {
                                  properties: {
                                    kubernetes: {
                                      properties: {
                                        'io/safe-to-evict': {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                      },
                                    },
                                  },
                                },
                                components: {
                                  properties: {
                                    gke: {
                                      properties: {
                                        'io/component-name': {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                        'io/component-version': {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                      },
                                    },
                                  },
                                },
                                gitlab: {
                                  properties: {
                                    'com/prometheus_port': {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                    'com/prometheus_scrape': {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                  },
                                },
                                monitoring: {
                                  properties: {
                                    gke: {
                                      properties: {
                                        'io/path': {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                      },
                                    },
                                  },
                                },
                                prometheus: {
                                  properties: {
                                    'io/port': {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                    'io/scrape': {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                  },
                                },
                                scheduler: {
                                  properties: {
                                    alpha: {
                                      properties: {
                                        kubernetes: {
                                          properties: {
                                            'io/critical-pod': {
                                              type: 'text',
                                              fields: {
                                                keyword: {
                                                  type: 'keyword',
                                                  ignore_above: 256,
                                                },
                                              },
                                            },
                                          },
                                        },
                                      },
                                    },
                                  },
                                },
                              },
                            },
                            labels: {
                              properties: {
                                addonmanager: {
                                  properties: {
                                    kubernetes: {
                                      properties: {
                                        'io/mode': {
                                          type: 'text',
                                          fields: {
                                            keyword: {
                                              type: 'keyword',
                                              ignore_above: 256,
                                            },
                                          },
                                        },
                                      },
                                    },
                                  },
                                },
                                app: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'k8s-app': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'pod-template-hash': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                'queue-pod-name': {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                release: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                shard: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                stage: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                tier: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                                type: {
                                  type: 'text',
                                  fields: {
                                    keyword: {
                                      type: 'keyword',
                                      ignore_above: 256,
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                      },
                    },
                    updateStrategy: {
                      properties: {
                        rollingUpdate: {
                          properties: {
                            maxUnavailable: {
                              type: 'long',
                            },
                          },
                        },
                        type: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                      },
                    },
                    validation: {
                      properties: {
                        openAPIV3Schema: {
                          properties: {
                            properties: {
                              properties: {
                                spec: {
                                  properties: {
                                    properties: {
                                      properties: {
                                        resourcePolicy: {
                                          properties: {
                                            properties: {
                                              properties: {
                                                containerPolicies: {
                                                  properties: {
                                                    items: {
                                                      properties: {
                                                        type: {
                                                          type: 'text',
                                                          fields: {
                                                            keyword: {
                                                              type: 'keyword',
                                                              ignore_above: 256,
                                                            },
                                                          },
                                                        },
                                                      },
                                                    },
                                                    type: {
                                                      type: 'text',
                                                      fields: {
                                                        keyword: {
                                                          type: 'keyword',
                                                          ignore_above: 256,
                                                        },
                                                      },
                                                    },
                                                  },
                                                },
                                              },
                                            },
                                            type: {
                                              type: 'text',
                                              fields: {
                                                keyword: {
                                                  type: 'keyword',
                                                  ignore_above: 256,
                                                },
                                              },
                                            },
                                          },
                                        },
                                        targetRef: {
                                          properties: {
                                            type: {
                                              type: 'text',
                                              fields: {
                                                keyword: {
                                                  type: 'keyword',
                                                  ignore_above: 256,
                                                },
                                              },
                                            },
                                          },
                                        },
                                        updatePolicy: {
                                          properties: {
                                            properties: {
                                              properties: {
                                                updateMode: {
                                                  properties: {
                                                    type: {
                                                      type: 'text',
                                                      fields: {
                                                        keyword: {
                                                          type: 'keyword',
                                                          ignore_above: 256,
                                                        },
                                                      },
                                                    },
                                                  },
                                                },
                                              },
                                            },
                                            type: {
                                              type: 'text',
                                              fields: {
                                                keyword: {
                                                  type: 'keyword',
                                                  ignore_above: 256,
                                                },
                                              },
                                            },
                                          },
                                        },
                                      },
                                    },
                                    type: {
                                      type: 'text',
                                      fields: {
                                        keyword: {
                                          type: 'keyword',
                                          ignore_above: 256,
                                        },
                                      },
                                    },
                                  },
                                },
                              },
                            },
                          },
                        },
                      },
                    },
                    version: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    versions: {
                      properties: {
                        name: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        served: {
                          type: 'boolean',
                        },
                        storage: {
                          type: 'boolean',
                        },
                      },
                    },
                    volumes: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                  },
                },
                status: {
                  properties: {
                    acceptedNames: {
                      properties: {
                        kind: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        listKind: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        plural: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        shortNames: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        singular: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                      },
                    },
                    availableReplicas: {
                      type: 'long',
                    },
                    conditions: {
                      properties: {
                        lastTransitionTime: {
                          type: 'date',
                        },
                        message: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        reason: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        status: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                        type: {
                          type: 'text',
                          fields: {
                            keyword: {
                              type: 'keyword',
                              ignore_above: 256,
                            },
                          },
                        },
                      },
                    },
                    currentNumberScheduled: {
                      type: 'long',
                    },
                    desiredNumberScheduled: {
                      type: 'long',
                    },
                    fullyLabeledReplicas: {
                      type: 'long',
                    },
                    numberAvailable: {
                      type: 'long',
                    },
                    numberMisscheduled: {
                      type: 'long',
                    },
                    numberReady: {
                      type: 'long',
                    },
                    observedGeneration: {
                      type: 'long',
                    },
                    readyReplicas: {
                      type: 'long',
                    },
                    replicas: {
                      type: 'long',
                    },
                    selector: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    storedVersions: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    updatedNumberScheduled: {
                      type: 'long',
                    },
                  },
                },
                subjects: {
                  properties: {
                    apiGroup: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    kind: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    name: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                    namespace: {
                      type: 'text',
                      fields: {
                        keyword: {
                          type: 'keyword',
                          ignore_above: 256,
                        },
                      },
                    },
                  },
                },
              },
            },
            serviceName: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
            status: {
              type: 'object',
            },
          },
        },
        receiveTimestamp: {
          type: 'date',
        },
        resource: {
          properties: {
            labels: {
              properties: {
                cluster_name: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                disk_id: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                instance_id: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                location: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                namespace_name: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                node_name: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                pod_name: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                project_id: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                snapshot_id: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
                zone: {
                  type: 'text',
                  fields: {
                    keyword: {
                      type: 'keyword',
                      ignore_above: 256,
                    },
                  },
                },
              },
            },
            type: {
              type: 'text',
              fields: {
                keyword: {
                  type: 'keyword',
                  ignore_above: 256,
                },
              },
            },
          },
        },
        severity: {
          type: 'text',
          fields: {
            keyword: {
              type: 'keyword',
              ignore_above: 256,
            },
          },
        },
        timestamp: {
          type: 'date',
        },
      },
    },
    message_id: {
      type: 'text',
      fields: {
        keyword: {
          type: 'keyword',
          ignore_above: 256,
        },
      },
    },
    publish_time: {
      type: 'date',
    },
    type: {
      type: 'text',
      fields: {
        keyword: {
          type: 'keyword',
          ignore_above: 256,
        },
      },
    },
  },
}
