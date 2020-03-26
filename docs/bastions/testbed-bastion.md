## testbed bastion hosts

##### How to start using them
Add the following to your `~/.ssh/config` (specify your username and path to ssh private key):
```
# GCP staging bastion host
Host lb-bastion.testbed.gitlab.com
        User                            YOUR_SSH_USERNAME

# testbed boxes
Host *.gitlab-testbed.internal
        PreferredAuthentications        publickey
        ProxyCommand                    ssh lb-bastion.testbed.gitlab.com -W %h:%p
```

Once your config is in place, test it by ssh'ing to the deploy host:

```
ssh deploy-01-sv-testbed.c.gitlab-testbed.internal
```

##### Console access

Currently we do not have a console host for testbed, to access the rails
console you can initiate it from one of the deploy host

```
ssh deploy-01-sv-testbed.c.gitlab-testbed.internal
sudo gitlab-rails console
```
