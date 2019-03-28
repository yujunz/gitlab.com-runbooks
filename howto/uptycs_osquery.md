# Overview

Security is using the [Uptycs](https://www.uptycs.com/) Security Analytics Platform which is based on [osquery](https://osquery.io/).

The osqueryd daemon is rolled out to staging and production by the [gitlab-uptycs cookbook](https://gitlab.com/gitlab-cookbooks/gitlab-uptycs) and is downloading it's configuration profile and sending query results from/to gitlab.uptycs.io which is controlled by the security team.

As osqueryd can consume many system resources - depending on configuration profile and node workload - we added [process_exporter metrics](https://prometheus.gprd.gitlab.net/graph?g0.range_input=30m&g0.expr=rate(namedprocess_namegroup_cpu_user_seconds_total%7Bgroupname%3D%22osqueryd%22%7D%5B5m%5D)&g0.tab=0) for the `osqueryd` process.

See [troubleshooting](../troubleshooting/uptycs_osqueryd.md) for common problems.