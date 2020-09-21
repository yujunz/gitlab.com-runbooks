# Workhorse Image Scaler Alerts

This runbook covers alerts related to Workhorse's built-in [image scaler](https://gitlab.com/gitlab-org/gitlab-workhorse/-/tree/master/internal/imageresizer).

Image scaling is not handled directly by workhorse itself, but a companion tool called `gitlab-resize-image`
(just "scaler" hereafter) that workhorse shells out to for every such request.

## `gitlab_workhorse_image_scaler_max_procs_exceeded_5m`

Since forking into a new process can be costly, we currently [cap the number of scaler processes](https://gitlab.com/gitlab-org/gitlab-workhorse/-/blob/master/internal/imageresizer/image_resizer.go#L43)
on any workhorse node so as not to lead to runaway resource consumption in face of increasing asset traffic.

Under normal circumstances, this threshold should never be tripped, since it implies that either we are getting
more scaler traffic than anticipated, or that image scalers are not completing quickly enough.

**NOTE**:

- we currently only rescale project, group and user avatars
- we only rescale PNGs and JPEGs
- we only rescale images when requesting a width defined by [`ALLOWED_IMAGE_SCALER_WIDTHS`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/concerns/avatarable.rb#L6)

### Symptoms and verification

User experience should not be affected, since we fail over to the original size in most cases, although site rendering
might slow down a bit due to larger images being served instead.

In Prometheus, [`gitlab_workhorse_image_resize_processes`](https://thanos-query.ops.gitlab.net/graph?g0.range_input=1h&g0.max_source_resolution=0s&g0.expr=gitlab_workhorse_image_resize_processes&g0.tab=1)
should show readings above the defined threshold.

In [Kibana](https://log.gprd.gitlab.net/goto/59e5e2b184397226d7653f72269ca79c), you may notice workhorse log entries such as:

```
ImageResizer: too many running scaler processes
```

Due to us failing over to the original image in theses cases, the error rate for this path should _not_ have increased.

This [Kibana dashboard](https://log.gprd.gitlab.net/app/kibana#/dashboard/4dd31390-fccf-11ea-af41-ad80f197fa45?_g=(filters%3A!()%2CrefreshInterval%3A(pause%3A!t%2Cvalue%3A0)%2Ctime%3A(from%3Anow-1h%2Cto%3Anow)))
provides a breakdown of image scaler latencies as well as a general overview of what is happening currently.

### Causes and remedies

Under normal conditions, a scaler process should be able to complete relatively quickly, on the order of a few
dozen milliseconds, and capacity for new instances should become available on an ongoing basis.
However, there are several reasons why that may not be happening, listed below.

#### The scaler is taking longer than expected to finish

We increment a counter when forking into the scaler and decrement again when it finishes. If the scaler is
taking an unusual amount of time, then the arrival rate of image scaling requests may outpace the ability
for running scaler processes to finish in time, thus tripping this alert.

In this case we should look at the affected workhorse nodes and:

- See if scaler processes are getting stuck by looking at process listings (look for `gitlab-resize-image` procs).
  To unclog the pipes, killing these processes might be the easiest remedy.
- See if scaler processes are finishing, but take a long time to complete (anything above a few dozen to a hundred
  milliseconds is too slow). The most likely explanation is that either the node is CPU starved (image scaling is
  a CPU bound operation) or that writing the scaled image back out to the client is taking a long time due to slow
  connection speed or other network bottlenecks.

#### There are too many inbound scaler requests

Even if the scaler operates quickly, it could be that there are too many inbound requests for image scaling,
thus tripping our threshold, and we have no backpressure mechanisms in place.

Image scaler requests are ordinary web requests to images served via the `/uploads/` path and which furthermore
carry a `width` parameter, e.g.:

- `/uploads/-/system/group/avatar/22/avatar_w300.png?width=16`
- `/uploads/-/system/user/avatar/1/avatar.png?width=64`

Consult [Kibana logs](https://log.gprd.gitlab.net/goto/583ffd1ef3d3d2f7870494fcc080eb4b)
and/or the following Grafana dashboards to understand whether there has been a spike in traffic
to these endpoints.

- [User avatars](https://dashboards.gitlab.net/d/web-rails-controller/web-rails-controller?orgId=1&var-PROMETHEUS_DS=Global&var-environment=gprd&var-stage=main&var-controller=UploadsController&var-action=show)
- [Project avatars](https://dashboards.gitlab.net/d/web-rails-controller/web-rails-controller?orgId=1&var-PROMETHEUS_DS=Global&var-environment=gprd&var-stage=main&var-controller=Projects::UploadsController&var-action=show)
- [Group avatars](https://dashboards.gitlab.net/d/web-rails-controller/web-rails-controller?orgId=1&var-PROMETHEUS_DS=Global&var-environment=gprd&var-stage=main&var-controller=Groups::UploadsController&var-action=show)

If the increase in traffic looks legit, we need to consider:

1. **Bumping up the scaler threshold.** If we think that node utilization looks healthy even when hitting the threshold,
   we should consider increasing the threshold.
1. **Adding more workhorse nodes.** To add relief to image scaling, as with any other workload served by workhorse,
   we may have to consider adding more nodes.
