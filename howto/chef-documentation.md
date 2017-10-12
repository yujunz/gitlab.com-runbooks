# Chef Tips and Tools

## Create New Cookbook

Creating new cookbook consists of several steps:

1. We have cookbook [template](https://gitlab.com/gitlab-cookbooks/template)
   which have all the necessary bits to speed up cookbook creation. To init
   new cookbook from template, do the following:
   1. Clone the template into new cookbook directory:
      ```
      git clone git@gitlab.com:gitlab-cookbooks/template.git gitlab_newcookbook
      ```
      Please use the `gitlab_` prefix for new cookbooks names.
   1. Replace the `template` with `gitlab_newcookbook` everywhere:
      ```
      find * -type f | xargs -n1 sed -i 's/template/gitlab_newcookbook/g'
      ls .kitchen*yml | xargs -n1 sed -i 's/template/gitlab_newcookbook/g'
      ```
      This will also update badges in README.md, attributes, and recipes.
   1. At this point, you have a fully functional initial commit with passing
      tests (see the Testing section in cookbooks README.md for details), and
      you can rewrite git commit history from template to you cookbook:
      ```
      git checkout --orphan latest && \
      git add -A && \
      git commit -am 'Initial commit'
      ```
      :point_up: the above may ask for GPG password if you sign your commits,
      so its separated from the branch switch below :point_down:
      ```
      git branch -D master && \
      git branch -m master && \
      sed -i 's/template/gitlab_newcookbook/' .git/config
      ```
1. Now its time to create two repos for your new cookbook. The main one, on
   `gitlab.com`, is used for everyday work, and template points to .com by
   default. The mirror cookbook on `dev.gitlab.org` is used by chef-server
   when gitlab.com is down, and should never be pushed directly to.
   1. Create a [new project](https://gitlab.com/projects/new?namespace_id=650153)
      in `gitlab-cookbooks` namespace (please use `gitlab_` prefix)
   1. Navigate to Settings->CI/CD of the newly created cookbook and add
      the `DIGITALOCEAN_ACCESS_TOKEN` environment variable to enable integration
      tests on DO in CI. Currently, we use the toke from Gitlab Dev account, get
      it from 1password or from another cookbook. We should use ephemeral ones
      for this (this is ongoing effort in Vault project)
   1. Navigate to Settings->Repository and expand "Push to a remote repository"
      group. You will need to add `dev.gitlab.org` mirror repository there. See
      the existing cookbooks for the example, and tick "Remote mirror repository".
   1. Create a [new project](https://dev.gitlab.org/projects/new?namespace_id=36)
      in `cookbooks` namespace on `dev.gitlab.org` with the same name. You can
      also add the `DIGITALOCEAN_ACCESS_TOKEN` there too, but since mirroring
      takes place after merge anyways, its not necessary.

1. Do a `git push origin master` and verify that the reposiory is mirrored to
   dev in few minutes.

1. Last step: tighten up push/merge rules to enforce some consistency of the
   cookbook. Since `dev.gitlab.org` is only mirror, and should never be used
   directly, the following is done only cookbook located on `gitlab.com`:
   1. Set some description in Settings -> General.
   1. Check "Merge request approvals" and add `@gl-infra` group to approvers under Settings -> General.
   1. Allow merge only with green pipelines and resolved discussions there too.
   1. Set "Check whether author is a GitLab user" and "Prevent committing secrets
      to Git" under Settings -> Repository. Make sure `master` branch is protected
      there too.
   1. Uncheck the "Public pipelines" under Settings -> Pipelines.

Go to the [chef-repo](https://dev.gitlab.org/cookbooks/chef-repo/) and edit the
Berksfile to add the new cookbook. Be sure that you add version pinning and point it to the
dev repo. Next, run `berks install` to download the cookbook for the first time, commit, and push.
Finally, run `berks upload <cookbookname>` to upload the cookbook to the Chef server.

To apply this uploaded cookbook to a new environment follow the steps [bellow](#Chef-Environments-and-Cookbooks)

## ChefSpec and test kitchen

For cookbooks with Makefiles in them, see the README.md for testing instructions.

### ChefSpec

ChefSpec and test kitchen are two ways that you can test your cookbook before you
commit/deploy it. From the documentation:

> ChefSpec is a framework that tests resources and recipes as part of a simulated chef-client run.
> ChefSpec tests execute very quickly. When used as part of the cookbook authoring workflow,
> ChefSpec tests are often the first indicator of problems that may exist within a cookbook.

To get started with ChefSpec you write tests in ruby to describe what you want. An example is:

```ruby
file '/tmp/explicit_action' do
  action :delete
end

file '/tmp/with_attributes' do
  user 'user'
  group 'group'
  backup false
  action :delete
end

file 'specifying the identity attribute' do
  path   '/tmp/identity_attribute'
 action :delete
end
```

There are many great resources for ChefSpec examples such as the [ChefSpec documentation](https://docs.chef.io/chefspec.html)
and the [ChefSpec examples on GitHub](https://github.com/sethvargo/chefspec/tree/master/examples).

### Test Kitchen/KitchenCI

[Test Kitchen/KitchenCI](http://kitchen.ci/) is a integration testing method that can spawn a VM
and run your cookbook inside of that VM. This lets you do somewhat more than just ChefSpec
and can be an extremely useful testing tool.

To begin with the KitchenCI, you will need to install the test-kitchen Gem `gem install test-kitchen`.
It would be wise to add this to your cookbook's Gemfile.

Next, you'll want to create the Kitchen's config file in your cookbook directory called `.kitchen.yml`.
This file contains the information that KitchenCI needs to actually run your cookbook. An example and explanation
is provided below.

```yaml
---
driver:
  name: vagrant

provisioner:
  name: chef_zero

platforms:
  - name: centos-7.1
  - name: ubuntu-14.04
  - name: windows-2012r2

suites:
  - name: client
    run_list:
      - recipe[postgresql::client]
  - name: server
    run_list:
      - recipe[postgresql::server]
```

This file is probably self-explanatory. It will use VirtualBox to build a VM and use `chef_zero` as the
method to converge your cookbook. It will run tests on 3 different OSes, CentOS, Ubuntu, and Windows 2012 R2.
Finally, it will run the recipes listed below based on the suite. The above config file will generate
6 VMs, 3 for the `client` suite and 3 for the `server` suite. You can customize this however you wish.
It is possible to run KitchenCI for an entire deployment, however I don't think our chef-repo is set up
in such a way.

As always, there are many resources such as the [KitchenCI getting started guide](http://kitchen.ci/docs/getting-started/)
and the [test-kitchen repo](https://github.com/test-kitchen/test-kitchen).

## Test cookbook on a local server

If you wish to test a cookbook on your local server versus KitchenCI, this is totally possible.

The following example is a way to run our GitLab prometheus cookbook locally.

```
mkdir -p ~/chef/cookbooks
cd ~/chef/cookbooks
git clone git@gitlab.com:gitlab-cookbooks/gitlab-prometheus.git
cd gitlab-prometheus
berks vendor ..
cd ..
chef-client -z -o 'recipe[gitlab-prometheus::prometheus]'
```

The `chef-client -z -o` in the above example will tell the client to run in local mode and
to only run the runlist provided.
You can substitute any cookbook you wish, including your own. Do keep in mind however that
this may still freak out when a chef-vault is involved.

## Update cookbook and deploy to production

When it comes time to edit a cookbook, you first need to clone it from its repo, most likely
in https://gitlab.com/gitlab-cookbooks/.

Once you make your changes to a cookbook, you will want to be sure to bump the version
number in metadata.rb as we have versioning requirements in place so Chef will not accept
a cookbook with the same version, even if it has changed. Commit these changes and submit a
merge request to merge your changes.

Once your changes are merged, you will need to actually upload the cookbook to the server.
To do this, go to the [chef-repo](https://dev.gitlab.org/cookbooks/chef-repo/) and run
`berks update <cookbookname>`. This will download the newest version of your cookbook.
Commit the changes that will be recorded in `Berksfile.lock` and push them. After the
cookbook is merged, you can use `berks upload <cookbookname>` to upload the cookbook
to the server.

To apply this uploaded version to a new environment follow the steps [bellow](#Chef-Environments-and-Cookbooks)

## Rollback cookbook

With the advent of environment pinned versions, rolling back a cookbook is as simple as
changing the version number back to the previous one in the respective environment file.

There is no need to delete the version, we can roll forward and upload a corrected 
version in its place.

## Chef Environments and Cookbooks

By utilizing environments in chef we are able to roll out our cookbooks to a subset
of our infrastructure. As an [environment](https://docs.chef.io/environments.html) we
divide up our infrastructure the same way was in terraform:

* [stg](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/environments/stg.json)(staging)
* [pre](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/environments/pre.json) (pre production)
* [cny](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/environments/cny.json) (canary)
* [prd](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/environments/prd.json) (production)

with the addition of the chef default environment:


* [\_default](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/environments/_default.json)

To see the nodes in an environment use a knife search command such as:

```
knife search node 'chef_environment:stg'|grep Name|sort
```

Each environment has a locked version for each GitLab cookbook which looks like this:

```
"gitlab-common": "= 0.2.0"
```

The pattern matching follows the same syntax as [gem or berks version operators](http://guides.rubygems.org/patterns/#declaring-dependencies)
(ie. <, >, <=, >=, ~>, =). This allows us to roll out a cookbook one environment at a time.
The workflow for this would look as follows:

We begin by uploading the cookbook as usual:
1. `berks update cookbook-name` and `berks upload cookbook-name` as usual

Now the version is on the chef server, but is only actively being applied to nodes in the `_default`
environment, since `_default` has no version constraints. The next steps are the same as
for any omnibus deploy:

1. deploy and test in staging
  1. edit the [environment file](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/environments/stg.json)
  1. upload the environment file `knife environment from file path/to/stg.json`
  1. verify changes (e.g. run `chef-client` on a server)
1. deploy and test in pre-production
  1. edit the [environment file](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/environments/pre.json)
  1. upload the environment file `knife environment from file path/to/pre.json`
  1. verify changes (e.g. run `chef-client` on a server)
1. deploy and test in canary
  1. edit the [environment file](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/environments/cny.json)
  1. upload the environment file `knife environment from file path/to/cny.json`
  1. verify changes (e.g. run `chef-client` on a server)
1. deploy and test in production
  1. edit the [environment file](https://dev.gitlab.org/cookbooks/chef-repo/blob/master/environments/prd.json)
  1. upload the environment file `knife environment from file path/to/prd.json`
  1. verify changes (e.g. run `chef-client` on a server)

This method does come with inherent risks: if this is done sloppily, it is possible that 
cookbook version can *fall under the table* and never be applied to an environment. We have
need a check in place to ensure that this does not happen. (e.g. compare the latest version 
on the chef server with the version in each environment, as well as the environments with 
each other).

## Run chef client in interactive mode

Really useful to troubleshoot.

Starting from the chef-repo folder run the following command:

```
$ chef-shell -z -c .chef/knife.rb
```

In here you can type `help` to get really useful help, but then for instance you can do this

```
> nodes.search('name:node-name-in-chef')
```

And then examine this node from chef's perspective

## References
  - [GitLab's chef-repo](https://dev.gitlab.org/cookbooks/chef-repo/)
  - [ChefSpec documentation](https://docs.chef.io/chefspec.html)
  - [ChefSpec examples on GitHub](https://github.com/sethvargo/chefspec/tree/master/examples)
  - [KitchenCI getting started guide](http://kitchen.ci/docs/getting-started/)
  - [test-kitchen repo](https://github.com/test-kitchen/test-kitchen)
