local grafana = import 'grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local basic = import 'basic.libsonnet';

basic.dashboard(
  'Application Demand Indicators',
  tags=['general'],
  time_from='now-6M',
  time_to='now',
)
.addPanels(
  layout.grid([
      grafana.text.new(
        title='Application Demand Indicators Help',
        mode='markdown',
        content=|||
          Application demand refers to how the application takes a user request and passes it on to the
          underlying infrastructure.

          For more information, please see the entry in the handbook page.
        |||
      ),
  ], cols=1, rowHeight=3, startRow=100)
  +
  layout.grid([
    basic.timeseries(
      title='Sidekiq - average operations per week',
      query=|||
        (sum by (env) (avg_over_time(gitlab_service_ops:rate{type="sidekiq", stage="main", env="gprd", monitor="global"}[1w]))
         or
         sum by (env) (avg_over_time(gitlab_service_ops:rate{type="sidekiq", stage="main", env="gprd", monitor!="global"}[1w]))
         ) * 86400 * 7
      |||,
      legendFormat="{{env}}"
    ),
  ], cols=1, rowHeight=12, startRow=100)
  +
  layout.grid([
    basic.timeseries(
      title='Redis - average operations per week',
      query=|||
        (sum by (env, type) (avg_over_time(gitlab_service_ops:rate{type=~"redis|redis-cache|redis-sidekiq", stage="main", env="gprd", monitor="global"}[1w]))
        or
        sum by (env, type) (avg_over_time(gitlab_service_ops:rate{type=~"redis(-cache|-sidekiq)?", stage="main", env="gprd", monitor!="global"}[1w]))
        ) * 86400 * 7
      |||,
      legendFormat="{{env}} - {{type}}"
    ),
  ], cols=1, rowHeight=12, startRow=100)
)