## pre bastion hosts

##### How to start using them
Add the following to your `~/.ssh/config` (specify your username and path to ssh private key):
```
# GCP staging bastion host
Host lb-bastion.pre.gitlab.com
        User                            YOUR_SSH_USERNAME

# pre boxes
Host *.gitlab-pre.internal
        PreferredAuthentications        publickey
        ProxyCommand                    ssh lb-bastion.pre.gitlab.com -W %h:%p
```

Once your config is in place, test it by ssh'ing to the deploy host:

```
ssh deploy-01-sv-pre.c.gitlab-pre.internal
```

##### Console access

Currently we do not have a console host for preprod, to access the rails
console you can initiate it from one of the deploy host

```
ssh deploy-01-sv-pre.c.gitlab-pre.internal
sudo gitlab-rails console
```
