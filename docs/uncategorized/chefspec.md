# Chefspec

We use chefspec for doing TDD with Chef

## Tests are taking too long to run

Sometimes tests take a lot of time to run, say, 13 seconds.

This could be due to a specific test being slow, or because of chefspec being slow in itself.

To troubleshoot there are 2 things that can be done:

### Profile the tests

This will point at which are the slowest tests, which can lead to a deeper investigation.

```
$ rspec -f d -c --profile

...

Top 10 slowest examples (3.2 seconds, 79.2% of total time):
  gitlab-prometheus::blackbox_exporter default execution creates a prometheus user and group
    0.61864 seconds ./spec/blackbox_spec.rb:26
  gitlab-prometheus::ceph_exporter default execution creates the runit service
    0.34689 seconds ./spec/ceph_exporter_spec.rb:22
  gitlab-prometheus::ceph_exporter default execution checkout ceph_exporter
    0.32843 seconds ./spec/ceph_exporter_spec.rb:14
  gitlab-prometheus::node_exporter default execution creates the runit service
    0.28103 seconds ./spec/node_exporter_spec.rb:35
  gitlab-prometheus::node_exporter default execution creates a prometheus user and group
    0.2806 seconds ./spec/node_exporter_spec.rb:10
  gitlab-prometheus::ceph_exporter default execution runs a execute with ceph_exporter
    0.28058 seconds ./spec/ceph_exporter_spec.rb:18
  gitlab-prometheus::ceph_exporter default execution installs librados-dev
    0.27605 seconds ./spec/ceph_exporter_spec.rb:10
  gitlab-prometheus::prometheus with a node exporter node registers the node-exporter node
    0.26639 seconds ./spec/prometheus_spec.rb:66
  gitlab-prometheus::node_exporter default execution creates the prometheus dir in the configured location
    0.26269 seconds ./spec/node_exporter_spec.rb:17
  gitlab-prometheus::node_exporter default execution creates the log dir in the configured location
    0.2549 seconds ./spec/node_exporter_spec.rb:26

Top 4 slowest example groups:
  gitlab-prometheus::ceph_exporter
    0.30836 seconds average (1.23 seconds / 4 examples) ./spec/ceph_exporter_spec.rb:3
  gitlab-prometheus::node_exporter
    0.27015 seconds average (1.08 seconds / 4 examples) ./spec/node_exporter_spec.rb:3
  gitlab-prometheus::prometheus
    0.267 seconds average (0.267 seconds / 1 example) ./spec/prometheus_spec.rb:3
  gitlab-prometheus::blackbox_exporter
    0.15838 seconds average (0.63353 seconds / 4 examples) ./spec/blackbox_spec.rb:4

Finished in 4.04 seconds (files took 3.27 seconds to load)
```

### Files take long to load

Also using `--profile`, pay attention to the last line

```
Finished in 15.51 seconds (files took 1 minute 41.58 seconds to load)
```

This is telling us that the tests themselves took 15 seconds, but loading the files took almost 2 minutes.

If this is the case, it seems that the [mix of ruby version and gems](https://github.com/sethvargo/chefspec/issues/492) are playing badly.

Further investigate by running this:

```
$ time ruby -e "require 'chefspec'"
ruby -e "require 'chefspec'"  79.85s user 2.78s system 98% cpu 1:23.76 total
```

This is proof enough to see that just loading chefspec is taking too long. So... replace your ruby.
