# Patroni 

## Scale Up

### Overview

If you are reading this runbook you are most likely tasked to scale up our Patroni cluster by certain number of nodes. Use this runbook as a guidance on how to safely scale up a Patroni cluster.

### Pre-requisite 

- Patroni
    This runbook assumes that you know what Patroni is, what and how we use it for and possible consequences that might come up if we do not approach this operation carefully. This is not to scare you away, but in the worst case: Patroni going down means we will lose our ability to preserve HA (High Availability) on Postgres. Postgres not being HA means if there is an issue with the primary node Postgres wouldn't be able to do a failover and GitLab would shut down to the world. Thus, this runbook assumes you know this ahead of time before you execute this runbook. 

- Terraform
    You are expected to know what Terraform is, how we use it and how we make change safely (`tf plan` first).  

### Scope

This runbook is intended only for one or more `read` replica node(s) of Patroni cluster. 

### Mental Model

A good mental model to have for this exercise is that we have a Patroni cluster running in production. There is a primary and several secondary/read-only nodes. Your first task is to spin up a node in our infra and get it configured. This is a pretty safe and straightforward process. After that, you would need to manually start the `patroni` service on the node. Once the `patroni` service starts up, it will register the node in the configured cluster in consul and start a `reinit` which will delete the current PGDATA dir and transfer a basebackup from the current leader. This will take a while (in the order of 6h). Once it is completed, streaming replication and replay of WAL files will begin (which also can take a while for replication lag to catch up). Only then, the node will be marked as ready and added to load-balancing to start receiving requests.

## Execution

### Preparation

- You should do this activity in a CR (thus, allowing you to practice all of it in staging first)
- After you have executed Step 3, you should silence alerts around replication lag for the new nodes. 

### Step 1

Increase the node count of patroni in [terraform](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/blob/master/environments/gstg/variables.tf). Scroll down, find the `variable "node_count"` section, `patroni` and bump up the corresponding number.

### Step 2

Apply the terraform and wait for chef to converge.

### Step 3

On the node, run: `systemctl enable patroni && systemctl start patroni`

### Step 4

On the new box, `gitlab-patronictl list` and ensure that the other cluster members are identical to those seen by running the same command on another cluster member. Also on the node, run `dig @127.0.0.1 -p 8600 db-replica.service.consul. SRV` to make sure the node shows up.

If you get an error `No module named 'psycopg2'` you need to do this: `pip install psycopg2 -t /opt/patroni/lib/python3.5/site-packages` (this is assuming we still support python3.5 when you are running this runbook)

### Step 5

Follow the patroni logs (`journalctl -u patroni`). A pg_basebackup will take several hours, after which streaming replication will begin. Have a look at `/var/log/gitlab/postgresql/postgresql.csv` if replaying WAL files is succeeding at this point. Check with `gitlab-patronictl list` - the node should go through the states `creating replica`, `starting`, `running`. Silence alerts as necessary.

## Automation Thoughts

Some steps of: https://ops.gitlab.net/gitlab-com/gl-infra/db-ops/-/blob/master/ansible/playbooks/roles/patroni/tasks/start_traffic.yml could be used in starting the traffic on a patroni node. And in the same project, further automation work would be contributed to.

## Reference

Majority of this runbook was written based on the content we have in: [patroni-management](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/patroni/patroni-management.md#scaling-the-cluster-up) and with some updates. But since we are going through a sprint of creating separate runbook for each activity, it makes sense to separate out the individual type of work into its own runbook. 