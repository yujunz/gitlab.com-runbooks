# Chef Tips and Tools

## Create New Cookbook

Firstly, create the repo for your new cookbook. You will need to create two, one on dev and one on GitLab.com.
Currently these are stored in the `gitlab-cookbooks/cookbookname` on GitLab.com and `cookbooks/cookbookname`
on dev. You will need to set up mirroring to the matching dev repo.

To create a new cookbook locally, run the command `chef generate cookbook <cookbookname>`.
This will create a new cookbook in the current directory with the cookbook name chosen.

At this time you can initialize the git repo in your cookbook and set origin to point
to GitLab.com.

You should then edit `cookbook/metadata.rb` to have an accurate description. This
is also where you will place any dependencies you need. 

After you've created the cookbook, be sure that it is pushed to both GitLab.com and dev.
Go to the [chef-repo](https://dev.gitlab.org/cookbooks/chef-repo/) and edit the 
Berksfile to add the new cookbook. Be sure that you add version pinning and point it to the
dev repo. Next, run `berks install` to download the cookbook for the first time, commit, and push.
Finally, run `berks upload <cookbookname>` to upload the cookbook to the Chef server.

## ChefSpec and test kitchen

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

Next, you'll want to create the Kitchen's config file in your cookbook directiry called `.kitchen.yml`.
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

This file is probably self explanitory. It will use VirtualBox to build a VM and use `chef_zero` as the 
method to converge your cookbook. It will run tests on 3 different OSes, CentOS, Ubuntu, and Windows 2012 R2.
Finally, it will run the recipes listed below based on the suite. The above config file will generate
6 VMs, 3 for the `client` suite and 3 for the `server` suite. You can customize this however you wish. While
our current chef-repo is not set up this way, it would be possible to use KitchenCI for an entire chef-repo, but 
it is far more common to use it only on one cookbook at a time.

As always, there are many resources such as the [KitchenCI getting started guide](http://kitchen.ci/docs/getting-started/)
and the [test-kitchen repo](https://github.com/test-kitchen/test-kitchen).

## Test cookbook on a local server

If you wish to test a cookbook on your local server versus KitchenCI, this is totally possible.

The following example is a way to run our GitLab prometheus cookbook locally.

```
mkdir -p ~/chef/cookbooks
cd ~/chef/cookbooks
git clone git@gitlab.com:gitlab-cookbooks/gitlab-prometheus.git
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

Once the cookbook is uploaded to the Chef server, the updates will be applied on the next
run of `chef-client`. On GitLab.com, this is about every 30 minutes. Alternatively,
you can always go run `chef-client` manually on whichever host needs the updates.

## Rollback cookbook


## Referrences
  - [GitLab's chef-repo](https://dev.gitlab.org/cookbooks/chef-repo/)
  - [ChefSpec documentation](https://docs.chef.io/chefspec.html)
  - [ChefSpec examples on GitHub](https://github.com/sethvargo/chefspec/tree/master/examples)
  - [KitchenCI getting started guide](http://kitchen.ci/docs/getting-started/)
  - [test-kitchen repo](https://github.com/test-kitchen/test-kitchen)
