local basic = import 'basic.libsonnet';
local layout = import 'layout.libsonnet';

{
  namedGroup(title, groupname, serviceType, serviceStage, startRow)::
    local formatConfig = {
      groupname: groupname,
      serviceType: serviceType,
      serviceStage: serviceStage,
    };

    layout.grid([
      basic.timeseries(
        title='Process CPU Time',
        description='Seconds of CPU time for the named process group, per second',
        query=|||
          sum(
            rate(
              namedprocess_namegroup_cpu_seconds_total{
                environment="$environment",
                groupname="%(groupname)s",
                type="%(serviceType)s",
                stage="%(serviceStage)s"
              }[$__interval]
            )
          ) without (mode)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        interval='1m',
        intervalFactor=1,
        format='s',
        legend_show=false,
        linewidth=1
      ),
      basic.timeseries(
        title=title + ': Open File Descriptors',
        description='Maximum number of open file descriptors per host',
        query=|||
          max(
              namedprocess_namegroup_open_filedesc{
                environment="$environment",
                groupname="%(groupname)s",
                type="%(serviceType)s",
                stage="%(serviceStage)s"
              }
          ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        interval='1m',
        intervalFactor=1,
        legend_show=false,
        linewidth=1
      ),
      basic.timeseries(
        title=title + ': Number of Threads',
        description='Number of threads in the process group',
        query=|||
          sum(
              namedprocess_namegroup_num_threads{
                environment="$environment",
                groupname="%(groupname)s",
                type="%(serviceType)s",
                stage="%(serviceStage)s"
              }
          ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        interval='1m',
        intervalFactor=1,
        legend_show=false,
        linewidth=1
      ),
      basic.timeseries(
        title=title + ': Memory Usage',
        description='Memory usage for named process group',
        query=|||
          sum(
              namedprocess_namegroup_memory_bytes{
                environment="$environment",
                groupname="%(groupname)s",
                type="%(serviceType)s",
                stage="%(serviceStage)s"
              }
          ) by (fqdn)
        ||| % formatConfig,
        legendFormat='{{ fqdn }}',
        interval='1m',
        format='bytes',
        intervalFactor=1,
        legend_show=false,
        linewidth=1
      ),
    ], startRow=startRow),
}
