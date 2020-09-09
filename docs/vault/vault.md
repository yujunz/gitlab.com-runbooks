# Gitlab Vault

## Vault configuration repository and setup
In order to minimise the amount of code repositories, systems, CI jobs, and user permissions needed, almost all Vault configuration has been isolated into a single Git repository at

https://ops.gitlab.net/infrastructure/workloads/vault/

This repository contains the terraform configuration for the Vault infrastructure, the `helmfile` configuration to deploy Vault onto GKE, and the terraform configuration to configure
the running Vault instance itself. The [README.md](https://ops.gitlab.net/infrastructure/workloads/vault/-/blob/master/README.md) inside the repository goes into its layout in more detail.

## Vault Architecture
Vault is a standard Kubernetes application run inside of an isolated GKE cluster. It is behind an `Ingress` object handled by [GCP HTTPS load balancing](https://cloud.google.com/load-balancing/docs/https). While the Vault application is highly available, Vault clustering relies on the [raft protocol](https://raft.github.io/), and thus the Vault application is deployed as a [StateFulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/). The data storage for Vault is handled by each pod having its own [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) to store its data. Vault naturally encrypts all data at rest. The PersistentVolumes underneath Vault are just [GCP Persistent Disks] dynamically generated and managed.

### Vault Seal Configuration
Every Vault instance has a [seal configuration](https://www.vaultproject.io/docs/concepts/seal). This means that every Vault installation, upon startup, is in a "Sealed" state and unable to be accessed. Typically Vault installations are either manually unsealed using keys distributed to people managing Vault, or automatically using [auto unseal](https://www.vaultproject.io/docs/concepts/seal#auto-unseal) combined with a specific secret key storage service. In our case, we rely on Vault auto-unseal with GKMS. This means that in any failure in GKE or Vault, when service is restored, Vault will be able automatically unseal itself and restore access automatically. It also means that because the seal is stored in GKMS, if an attacker was to get access to the contents of Vault storage, they would be unable to unseal and access the contents outside the specific Vault deployment environment.

## Vault Environments
We currently have two specific Vault instances setup to provide secrets to our infrastructure. The Two Vault instances are

* https://vault.gitlab.net For `gprd` and `ops` environments
* https://vault-nonprod.gitlab.net For `gstg` and `pre` environments

## Connecting to a Vault instance
As we only expose the Vault HTTPS endpoints inside our GKE networks (not externally to the internet), in order to connect to and talk to the Vault instances, we need to establish connectivity to our internal GKE network via the console hosts. To do this easily, we typically leverage the [sshuttle](https://github.com/sshuttle/sshuttle) tool to provide network access over ssh.

### Connecting to vault.gitlab.net application
Install `sshuttle` and run the following from a terminal
```shell
sshuttle -r console-01-sv-gprd.c.gitlab-production.internal `dig +short vault.gitlab.net`/32
# in another window
export VAULT_ADDR=https://vault.gitlab.net
```

The root token (with full admin privileges) for Vault is in 1password

### Connecting to vault-nonprod.gitlab.net application
Install `sshuttle` and run the following from a terminal
```shell
sshuttle -r console-01-sv-gprd.c.gitlab-production.internal `dig +short vault-nonprod.gitlab.net`/32
# in another window
export VAULT_ADDR=https://vault-nonprod.gitlab.net
```

The root token (with full admin privileges) for Vault-nonprod is in 1password

### Connecting to the vault.gitlab.net GKE cluster
Install `sshuttle` and run the following from a terminal
```shell
gcloud --project gitlab-vault container clusters get-credentials vault-gitlab-gke --region us-east1
sshuttle -r console-01-sv-gprd.c.gitlab-production.internal `gcloud --project gitlab-vault container clusters describe vault-gitlab-gke --region us-east1 --format 'value(endpoint)'`/32
```

### Connecting to the vault-nonprod.gitlab.net GKE cluster
Install `sshuttle` and run the following from a terminal
```shell
gcloud --project gitlab-vault-nonprod container clusters get-credentials vault-gitlab-gke --region us-east1
sshuttle -r console-01-sv-gprd.c.gitlab-production.internal `gcloud --project gitlab-vault-nonprod container clusters describe vault-gitlab-gke --region us-east1 --format 'value(endpoint)'`/32
```

## Troubleshooting
### Determining Pod status and logs
Follow the instructions to connect to the appropriate GKE cluster, then list/look at all pods in the `vault` namespace
```shell
kubectl -n gitlab get pods
kubectl -n gitlab logs vault-0
```

### Determining status of Vault from Vault itself
You can either setup `sshuttle` access to the Vault instance and login to it, or connect to one of the Vault pods and running 
```
kubectl -n vault exec -it vault-0 sh
$ vault status
# Ensure `Initialized` is `true` and `Sealed` is `false`
$ vault login
# enter root token
$ vault operator raft list-peers
# Ensure all vault pods are listed and their `State` is either `leader` or `follower`
```

## Backing up and restoring Vault
To be completed once https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10129 has been completed.
