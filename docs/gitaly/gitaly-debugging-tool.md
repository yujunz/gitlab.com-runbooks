# Debugging gitaly with gitaly-debug

In GitLab 11.6 and up, Gitaly comes with a debugging tool `gitaly-debug`
that can be run on a production Gitaly server. It is meant to avoid
having to copy-paste shell scripts when troubleshooting. For a list of
its current abilities, see the [gitaly-debug
README](https://gitlab.com/gitlab-org/gitaly/blob/master/cmd/gitaly-debug/README.md).

As of 11.6 the only feature of `gitaly-debug` is to simulate the
server-side workload of a Git clone on a specific repo. We hope to add
more tools over time.
