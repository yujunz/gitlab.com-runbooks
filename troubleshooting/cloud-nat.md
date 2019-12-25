# Cloud NAT Troubleshooting

## Background

Unless a static IP is needed for ingress, most of our GCP VMs should not have
static IPs and should access the internet via a managed Cloud NAT instance. This
service divides a pool of IPs, each with a number of TCP and UDP ports available
for NAT mapping, between VMs in its covered region/subnetworks, by dedicating a
configurable number of these ports to each VM.

## High Cloud NAT error rate

Most likely an alert brought you here, or you noticed an elevated error rate in
[the dashboard](https://dashboards.gitlab.net/d/nat-main/nat-cloud-nat?orgId=1&refresh=30s).

Option 1: Do nothing. Periodic bursts of NAT errors are seen as dropped packets
by clients, and higher-layer protocols should retry. However, sometimes a large
sustained error rate will cause errors. Note that if the environment in question
is CI, raising the NAT ports per VM will allow user jobs to create more
concurrent connections to the same outbound address, which may not be desirable.

Option 2: increase NAT port space:

1. Locate the terraform declaration for the NAT instance in question in
   gitlab-com-infrastructure. This will be an instance of the `cloud-nat`
   module.
1. Bump `nat_ports_per_vm`.
1. Verify that we will still have enough IPs in the instance's pool for all VMs.
   Use the formula:

   nat_ip_count = M * P / 64,512

   Where:

   M = number of machines in the region/subnets (multiply by some generous number to account for future growth)
   P = NAT ports per VM (see a variable below)

   https://cloud.google.com/nat/docs/overview#number_of_nat_ports_and_connections

1. If we would run out of ports according to the above formula, raise either
   `nat_ip_count` or `imported_ip_count` (whichever is set). Note that
   `imported_ip_count` will only be a variable if
   https://ops.gitlab.net/gitlab-com/gl-infra/terraform-modules/google/cloud-nat/merge_requests/11
   is merged.
