# Chef Tips and Tools

## Create New Cookbook

Firstly, create the repo for your new cookbook. You will need to create two, one on dev and one on GitLab.com.
Currently these are stored in the `gitlab-cookbooks/cookbookname` on GitLab.com and `cookbooks/cookbookname`
on dev.

To create a new cookbook locally, run the command `chef generate cookbook <cookbookname>`.
This will create a new cookbook in the current directory with the cookbook name chosen.

At this time you can initialize the git repo in your cookbook and set it origin to point
to GitLab.com. You will need to set up mirroring to the matching dev repo.

You should then edit `cookbook/metadata.rb` to have an accurate description. This
is also where you will place any dependencies you need. 

After you've created the cookbook, be sure that it is pushed to both GitLab.com and dev.
Go to the [chef-repo](https://dev.gitlab.org/cookbooks/chef-repo/) and edit the 
Berksfile to add the new cookbook. Be sure that you add version pinning and point it to the
dev repo. Next, run `berks install` to download the cookbook for the first time, commit, and push.
Finally, run `berks upload <cookbookname>` to upload the cookbook to the Chef server.

## Chef spec and test kitchen

## Test cookbook on local server

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

