# Deploying a change to gitlab.rb

From time to time we deploy changes that result in modifications to gitlab.rb.  These are distilled notes from one such occurrence which may provide context and confidence to future SRE's.  It is by no means fully comprehensive, but should help let you know which questions still need to be asked.

## Lay of the land

`/etc/gitlab/gitlab.rb` is the source of truth which Omnibus uses to generate the configuration of the various GitLab components.  Chef is involved *twice*, in different contexts, which is an important point.

1. GitLab's infrastructure level chef installation runs on nodes roughly every 30 minutes.  This:
    1. Deploys a change to gitlab.rb, typically because a cookbook changed or a secret was changed in GKMS encrypted vaults or similar.
    1. Triggers a `gitlab-ctl reconfigure` (from gitlab.rb changing)
1. The reconfigure will run a local chef deployed by the omnibus package, with omnibus recipes.  This:.
    1. Updates the config files of various components (commonly YAML) in their canonical locations, based on the contents of gitlab.rb
    1. Restarts/reloads/kicks components if necessary

## Implications

For GitLab.com, we mostly deploy individual components to distinct sets of machines (e.g. gitaly, sidekiq, postgres, web/unicorn), controlled by various 'enabled' flags in gitlab.rb.  The corollary of this is that `gitlab-ctl reconfigure` will only touch the config files of components that are affected by the change to gitlab.rb.  So if, for example, your change only affects the gitlab-rails component on the frontend web machines, it's quite safe to only manually shepherd the change on that class of machines, and let it just be deployed naturally on all the others.   Of course determining the class of machines affected can still be challenging; you may have to ask around, or go spelunking through omnibus-gitlab to confirm.

A non-obvious detail: some components, notably gitlab-rails (running under unicorn) and possibly gitaly also (TBC), have a safe and clean restart operation; it's actually a HUP, and can be done safely without any extra effort (e.g. no need to drain from the load balancer while the restart occurs)

## Known process

For a recent change to the omniauth providers, this process was followed.  It's a good starting point to derive a process for your change.

1. Stop chef on the nodes where changes need to be somewhat carefully shepherded through; in this case, web (because scary and the most affected), and API because we want to ensure we don't restart them all too close together
```
knife ssh 'roles:gstg-base-fe-web' 'sudo systemctl stop chef-client
knife ssh 'roles:gstg-base-fe-api' 'sudo systemctl stop chef-client
```

1. Make the change to the GKMS encrypted vault using gkms-vault-edit

1. On the web nodes, run "sudo chef-client".  This runs chef and per above updates gitlab.rb, runs `gitlab-ctl reconfigure` which regenerates config files and HUP's unicorn.
    * Note that you may like to do one or two manually/sequentially to verify the change is correct, but then you could reasonably run them in batches with knife, e.g. ```knife ssh 'roles:gstg-base-fe-web' -C3 'sudo chef-client'```.  This will be a fairly short no-op on the ones already done, then will complete the rest in batches of 3.

1. On the api nodes, run "sudo chef-client", in batches.  Similar as for the 'web' nodes, but this is not because there will be a noticeable change in behavior, just to ensure we don't restart all the API servers at once causing a blip:
    * ```knife ssh 'roles:gstg-base-fe-api' -C3 "sudo chef-client"```

Note also that running chef by hand will cause the daemon to be started up, so there's no need to manually start the chef-client service afterwards.

## Where can I find out more?

In slack:
1. [#g\_distribution](https://gitlab.slack.com/messages/g_distribution) are experts in omnibus packaging.
1. [#infrastructure-lounge](https://gitlab.slack.com/messages/infrastructure-lounge) (just barely) contains the SRE's who between them have a fair amount of experience with doing these things for real, and are happy to help

Omnibus [source code](https://gitlab.com/gitlab-org/omnibus-gitlab/): The chef content is in files/gitlab-cookbooks/
