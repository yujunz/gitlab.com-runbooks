## Disable Chef runs on a VM


Occasionally there will be a legitimate reason to stop Chef on a Chef managed
GitLab VM. You should follow the following steps to ensure that it both
communicates the reason for stopping Chef and prevents someone else from
starting the chef-client service when it is intentionally disabled.

**Stopping Chef should never ben done unless it is absolutely needed and should
never be stopped for more than 12 hours without a corresponding issue**

### Disable Chef runs

```
sudo service chef-client stop
# Examples: mv /etc/chef /etc/chef.disabled.because.of.pg.conf.override
#           mv /etc/chef /etc/chef.infra-1231
sudo mv /etc/chef /etc/chef.{reason}
```

### Enable Chef runs

```
sudo mv /etc/chef.{reason} /etc/chef
sudo service chef-client start
```
