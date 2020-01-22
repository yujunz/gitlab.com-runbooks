local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local customQuery = metricsCatalog.customQuery;

{
  type: 'frontend',
  tier: 'lb',
  slos: {
    apdexRatio: 0.9,
    errorRatio: 0.0005,
  },
  components: {
    mainHttpServices: {
      staticLabels: {
        stage: 'main',
      },

      apdex: histogramApdex(
        histogram='haproxy_http_response_duration_seconds_bucket',
        selector='type="frontend", backend_name!~"canary_.*", backend_name!="api_rate_limit", backend_name!="websockets"',
        satisfiedThreshold=5
      ),

      requestRate: rateMetric(
        counter='haproxy_backend_http_responses_total',
        selector='type="frontend", backend!~"canary_.*"'
      ),

      errorRate: rateMetric(
        counter='haproxy_backend_response_errors_total',
        selector='type="frontend", backend!~"canary_.*"'
      ),
    },

    cnyHttpServices: {
      staticLabels: {
        stage: 'cny',
      },

      apdex: histogramApdex(
        histogram='haproxy_http_response_duration_seconds_bucket',
        selector='type="frontend", backend_name=~"canary_.*"',
        satisfiedThreshold=5
      ),

      requestRate: rateMetric(
        counter='haproxy_backend_http_responses_total',
        selector='type="frontend", backend=~"canary_.*"'
      ),

      errorRate: rateMetric(
        counter='haproxy_backend_response_errors_total',
        selector='type="frontend", backend=~"canary_.*", '
      ),
    },

    sshServices: {
      apdex: histogramApdex(
        histogram='haproxy_ssh_request_duration_seconds_bucket',
        selector='type="frontend"',
        satisfiedThreshold=8
      ),

      requestRate: rateMetric(
        counter='haproxy_ssh_requests_total',
        selector='type="frontend"'
      ),


      // We only want to keep track of errors that our our fault (not the clients)
      // These are some explanations of the relevant codes, from the haproxy docs
      //
      // K : the session was actively killed by an admin operating on haproxy.
      // S : the TCP session was unexpectedly aborted by the server, or the server explicitly refused it.
      // s : the server-side timeout expired while waiting for the server to send or receive data.
      // P : the session was prematurely aborted by the proxy, because of a connection limit enforcement,
      //     because a DENY filter was matched, because of a security check which detected and blocked a
      //     dangerous error in server response which might have caused information leak
      // R : a resource on the proxy has been exhausted (memory, sockets, source ports, ...).
      //     Usually, this appears during the connection phase, and system logs should contain a copy of
      //     the precise error. If this happens, it must be considered as a very serious anomaly which
      //     should be fixed as soon as possible by any means.
      // I : an internal error was identified by the proxy during a self-check.
      //     This should NEVER happen, and you are encouraged to report any log
      //     containing this, because this would almost certainly be a bug. It
      //     would be wise to preventively restart the process after such an
      //     event too, in case it would be caused by memory corruption.
      // D : the session was killed by haproxy because the server was detected
      //     as down and was configured to kill all connections when going down.
      errorRate: rateMetric(
        counter='haproxy_ssh_requests_terminated_total',
        selector='type="frontend", cause=~"K|S|s|P|I|D"'
      ),
    },
  },
}
