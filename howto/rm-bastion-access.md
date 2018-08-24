# Set up bastions for Release managers

All SSH commands need to be proxied trough one of the bastion
hosts. As part of the release manager onboarding, you should already
have provided your SSH key to the infrastructure team, and they should
have added that key to the required hosts.

So first, let's make sure you have access to those bastions.

Run the following command to check access to the gstg bastions:

```
ssh <username>@lb-bastion.gstg.gitlab.com
```

and use this command to check access to the gprd bastions:

```
ssh <username>@lb-bastion.gprd.gitlab.com
```

If that works, you can add this config to your `~/.ssh/config` to make
sure all commands for the staging and production environments are
routed trough those bastions:

```
# gstg boxes
Host *.gitlab-staging-1.internal
  PreferredAuthentications publickey
  ProxyCommand ssh <username>@lb-bastion.gstg.gitlab.com -W %h:%p

# gprd boxes
Host *.gitlab-production.internal
  PreferredAuthentications publickey
  ProxyCommand ssh <username>@lb-bastion.gprd.gitlab.com -W %h:%p
```

If everything is configured correctly, you should be able to SSH into
different nodes, you could try that out by SSH'ing into a sidekiq
node:

For staging:

```
ssh sidekiq-besteffort-01-sv-gstg.c.gitlab-staging-1.internal
```

For production:

```
ssh sidekiq-besteffort-01-sv-gprd.c.gitlab-production.internal
```
