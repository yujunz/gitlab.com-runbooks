## Summary

This document tracks the subnet allocation across multiple infrastructure
projects related to GitLab.com. Any project that requires centralized monitoring
or maintenance from ops runners should be configured to not overlap with the
gitlab-ops project for network peering.

* This doc replaces the previous [tracking spreadsheet on google docs](https://docs.google.com/spreadsheets/d/1l-Oxx8dqHqGnrQ23iVP9XGYariFGPFDuZkqFj4KOe5A/edit#gid=0)
* All environments listed on the [handbook environments page](https://about.gitlab.com/handbook/engineering/infrastructure/environments/) are covered here

## Reserving a new subnet

- Update this MR with a new allocation, pick a row that has `AVAILABE GCP`, if
  needed we can start using previously allocated subnets for Azure
- Larger subnets can be split into smaller ones, if necessary

## Subnet Allocations

| First IP | Last IP | Subnet | Project | Description
| -------  | ------  | -----  | ------  | --------
| `10.0.0.0`      | `10.31.255.255`    | `10.0.0.0/11`    | N/A              | RESERVED
| `10.32.0.0`     | `10.63.255.255`    | `10.32.0.0/11`   | N/A              | Legacy Azure
| `10.32.0.0`     | `10.35.255.255`    | `10.32.0.0/14`   | SnowPlow         | AWS-SnowPlow
| `10.36.0.0`     | `10.39.255.255`    | `10.36.0.0/14`   | N/A              | Legacy Azure
| `10.40.0.0`     | `10.43.255.255`    | `10.40.0.0/14`   | N/A              | Legacy Azure
| `10.44.0.0`     | `10.47.255.255`    | `10.44.0.0/14`   | N/A              | Legacy Azure
| `10.48.0.0`     | `10.63.255.255`    | `10.48.0.0/12`   | N/A              | Legacy Azure
| `10.64.0.0`     | `10.95.255.255`    | `10.64.0.0/11`   | N/A              | Legacy Azure
| `10.96.0.0`     | `10.127.255.255`   | `10.96.0.0/11`   | N/A              | Legacy Azure
| `10.128.0.0`    | `10.159.255.255`   | `10.28.0.0/11`   | N/A              | Legacy Azure
| `10.160.0.0`    | `10.163.255.255`   | `10.160.0.0/14`  | gitlab-analysis              | GKE pods
| `10.164.0.0`    | `10.167.255.255`   | `10.164.0.0/14`  | gitlab-analysis              | GKE pods
| `10.168.0.0`    | `10.175.255.255`   | `10.168.0.0/13`  | N/A              | AVAILABLE GCP
| `10.176.0.0`    | `10.183.255.255`   | `10.176.0.0/13`  | N/A              | AVAILABLE GCP
| `10.184.0.0`    | `10.191.255.255`   | `10.184.0.0/13`  | N/A              | AVAILABLE GCP
| `10.192.0.0`    | `10.199.255.255`   | `10.192.0.0/13`  | N/A              | Legacy Azure
| `10.200.0.0`    | `10.207.255.255`   | `10.200.0.0/13`  | N/A              | Legacy Azure
| `10.208.0.0`    | `10.215.255.255`   | `10.208.0.0/13`  | N/A              | Legacy Azure
| `10.216.0.0`    | `10.223.255.255`   | `10.216.0.0/13`  | gitlab-production| **Production GCP**
| `10.224.0.0`    | `10.231.255.255`   | `10.224.0.0/13`  | gitlab-staging   | **Staging GCP**
| `10.232.0.0`    | `10.239.255.255`   | `10.232.0.0/13`  | gitlab-pre       | **PreProd GCP**
| `10.240.0.0`    | `10.247.255.255`   | `10.247.0.0/13`  | gitlab-testbed   | **Testbed GCP**
| `10.248.0.0`    | `10.248.255.255`   | `10.248.0.0/16`  | N/A              | Legacy Azure
| `10.249.0.0`    | `10.249.255.255`   | `10.249.0.0/16`  | N/A              | AVAILABLE GCP
| `10.250.0.0`    | `10.250.255.255`   | `10.250.0.0/16`  | gitlab-ops       | **Ops GCP**
| `10.251.0.0`    | `10.251.255.255`   | `10.251.0.0/16`  | N/A              | AVAILABLE GCP
| `10.252.0.0`    | `10.252.255.255`   | `10.252.0.0/16`  | gitlab-restore   | **Restore GCP**
| `10.253.0.0`    | `10.253.255.255`   | `10.253.0.0/16`  | N/A              | AVAILABLE GCP
| `10.254.0.0`    | `10.254.255.255`   | `10.254.0.0/16`  | N/A              | Legacy Azure
| `10.255.0.0`    | `10.255.255.255`   | `10.255.0.0/16`  | N/A              | AVAILABLE GCP
