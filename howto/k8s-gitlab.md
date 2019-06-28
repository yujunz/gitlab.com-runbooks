## GitLab.com on Kubernetes

The following is a high level guide on what it takes to build out the necessary
bits for adding GKE and bringing over components of GitLab into Kubernetes.

Our current application configuration components:
* https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com
* https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/monitoring

1. Create the cluster configuration in terraform, we'll need the following
   items:
    * IP address for Cloud NAT
    * IP address for ingress into GitLab product (nginx ingress)
    * Internal IP address for prometheus service
    * Cloud NAT device
    * Router for the Cloud NAT
    * Cluster - we'll use our gke submodule https://gitlab.com/gitlab-com/gl-infra/terraform-modules/google/gke which will build out the following
      items:
      * cluster
      * 1 node pool
      * the required network - subnetwork and secondary networks
    * Logging pubsub instance
    * Create an IAM user for operations on CI/CD and inside of our cluster
    * Example of all the above via terraform: https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/merge_requests/839
1. Set IAM user permissions on cluster
    * This is manual, documented here: https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/blob/master/README.md#service-account
1. Create a DNS record for the new registry
    * This is in route53, use the `gitlab-com` external static IP and create an
      A record like so: `registry.gke.<ENVIRONMENT>.gitlab.com`
1. Set the appropriate environment variables in the application configuration repos
    * Repos:
      * https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/settings/ci_cd
      * https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/monitoring/-/settings/ci_cd
    * ENV Vars:
      * `SERVICE_KEY`
1. Create the application configurations
    * We'll need the IP address created from above, until: https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/7108
    * the monitoring repo will readily take the internal IP provisioned above automatically
    * Adjust any necessary configurations or additions by following the README's
      in each of our application configuration repos.
    * Example Merge Requests:
      * Monitoring: https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/monitoring/merge_requests/12
      * GitLab.com: https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/merge_requests/5
    * Note that when merged to master, CI/CD will fail, so it would be advised
      to hold off until after the next few steps
1. Take care of any manual actions from our new configuration:
    * https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/blob/d8daab846f440d1f0aff63c47c4d1aec62632ce7/HELM_README.md
1. Perform the installation of each of our components
    * Locally we'll perform the install, `cd` into each of the components' repo
      and then run: `./bin/install -e <ENVIRONMENT>`
    * Troubleshoot where necessary
1. We can now merge any commits associated with these repos, and CI/CD should
   work successfully
1. Validate the registry is working properly
    * Using the above DNS record you should be able to log into the docker
      registry, example: `docker login registry.gke.staging.gitlab.com`
    * And you should also be able to successfully push and pull images
1. Create the chef configuration for ingress traffic and enable it (sends all registry traffic to GKE)
    * Example Merge Request: https://ops.gitlab.net/gitlab-cookbooks/chef-repo/merge_requests/131
1. Add data source to grafana to our new GKE cluster
    * This is currently done by hand: https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/6955
    * Login as an admin into https://dashboards.gitlab.net
    * Go to Datasources>Add
    * Name: <NAME OF CLUSTER>
    * URL: `http://<IP OF PROMETHEUS SERVICE>:9090` - this is a class A IP address as defined by our terraform configs
    * Save and test
