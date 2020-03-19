# Upgrade camoproxy

## Update the cookbook
* Download the desired version of go-camo from https://github.com/cactus/go-camo/releases to your workstation
* Verify the SHA256 sum of that file against the SHA256 file also available at the above URL
* In the gitlab-camoproxy cookbook, edit attributes/default.rb.  Update the fields:
   * checksum - the SHA256 sum you just verified
   * version - the selected version e.g. 2.1.2
   * go\_version - this is part of the URL/filename, and changes occasionally
* Release/update the cookbook via the usual [method](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/#workflow-for-cookbook-changes)

## Verify
* Once the version has been bumped on staging, run chef-client on the camoproxy nodes (or wait for it to run naturally)
* Verify that the basic operation is still correct by viewing https://user-content.staging.gitlab-static.net/54a746f78e2d0a61234493b8ec35fde9772f633a/68747470733a2f2f7777772e7374726f7070796b697474656e2e636f6d2f696d616765732f6f70732d70726f626c656d2d6e6f772e6a7067
   * This should show an amusing image, unless the HMAC has been changed.  If you need to generate a fresh URL to test with, see [../docs/uncategorized/camoproxy.md#manual-testing]
* If relevant, verify any other changes that triggered the need for upgrade

## Release to production
* Run the apply\_to\_prod job on the chef-repo version bump MR
* Either wait for chef to run naturally, or run it manually on the production camoproxy nodes.  Note that the upgrade/restart process is pretty lightweight, and the rate-of-requests to camoproxy is low enough that it's not necessary to take any particular precautions around timing or dropping nodes from the load balancer.
* Verify basic operations: https://user-content.gitlab-static.net/bcbb0d4c7a61aefb3ec2fab34d694f5e49a923ab/68747470733a2f2f7777772e7374726f7070796b697474656e2e636f6d2f696d616765732f6f70732d70726f626c656d2d6e6f772e6a7067 should be the same image as in staging
* If relevant, verify any other changes that triggered the need for upgrade
