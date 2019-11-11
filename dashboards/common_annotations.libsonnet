local grafana = import 'grafonnet/grafana.libsonnet';
local annotation = grafana.annotation;

{
  deploymentsForEnvironment:: annotation.datasource(
    'deploy',
     '-- Grafana --',
    tags=['deploy', '$environment'],
    builtIn=1,
    iconColor='#96D98D',
  ),
  deploymentsForEnvironmentCanary:: annotation.datasource(
    'canary-deploy',
     '-- Grafana --',
    tags=['deploy', '${environment}-cny'],
    builtIn=1,
    iconColor='#FFEE52',
  ),
}
