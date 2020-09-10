local grafana = import './grafana.libsonnet';
local test = import 'github.com/yugui/jsonnetunit/jsonnetunit/test.libsonnet';

test.suite({
  testGenerateMarkdownBlank: {
    actual: grafana.grafana('Dash', 'dash', vars={ moo: 'cow', bat: 'ozzy' })(options={}),
    expect: [{
      title: 'Grafana: Dash',
      url: '/d/dash?var-bat=ozzy&var-moo=cow',
    }],
  },
})
