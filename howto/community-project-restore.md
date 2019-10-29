## Community Project Restoration
This document goes into the necessary details to assist in restoring an
accidental deletion of a GitLab project.

### Components
* Database
* Project Repo Data
* Project Wiki Data
* There's more but we haven't encountered/practiced necessary mechanisms for a
  restoration.  Examples, Container Registry data and artifacts

### Coordination
* A restoration process should be assigned to available team members (SRE, DBRE) and
  coordination will govern how to progress through this process
* It is strongly suggested to read through this entire document before
  proceeding to ensure one can answer all required questions and agree upon a
  validation method

### Database

If a project is deleted in GitLab, it is entirely removed from the database. That is, we also lack necessary meta data to recover data from file servers. Recovering meta- and project data is a multi step process:

1. Restore a full database backup and perform point-in time recovery (PITR)
2. Extract meta data necessary to recover from git/wiki data from file servers
3. Export the project from the database backup and import into GitLab

#### Restore full database backup and perform PITR

In order to restore a database backup, we leverage the backup restore pipeline. It can be configured to start a new GCE instance and restore a backup to an exact point in time for later recovery ([example MR](https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/postgres-gprd/merge_requests/8/diffs)).

Important notes related to the provisioning using CI/CD pipelines of the "gitlab-restore" project:
1. You can start the process in [CI/CD Pipelines](https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/postgres-gprd/pipelines) of the "gitlab-restore" project.
1. To perform PITR for the production database, use CI/CD variable `ENVIRONMENT` set to `gprd`. The default value is `gstg` meaning that the staging database will be restored.
1. To ensure that your instance won't get destroyed in the end, set CI/CD variable `NO_CLEANUP` to `1`.
1. In CI/CD Pipelines, when starting a new pipeline, you can choose any Git branch. But if you use something except `master`, there are high chances that production DB copy won't fit the disk. So, use `GCE_DATADISK_SIZE` CI/CD variable to provision an instance with a large enough disk. As of October 2019, we need to use `5000` (5000 GiB). Check the `GCE_DATADISK_SIZE` value that is currently used in the backup verification schedules (see [CI/CD Schedules](https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/postgres-gprd/pipeline_schedules)).
1. It is recommended (although not required) to specify the intance name using CI/CD variable `INSTANCE_NAME`. Custom names help distinguish GCE instances from auto-provisioned and from provisioned by someone else. An excellent example of custom name: `nik-gprd-infrastructure-issue-1234` (means: requested by `nik`, for environment `gprd`, for the the `infrastructure` issue `1234`). If the custom name is not set, your instance gets a name like `restore-postgres-gprd-XXXXX`, where `XXXXX` is the CI/CD pipeline ID.
1. To control the process, SSH to the intance. The main items to check:
    - `df -hT /var/opt/gitlab` to ensure that the disk is not full (if it hits 100%, it won't be noticeable in the CI/CD interfaces, unfortunately),
    - `sudo journalctl -f` to see basebackup fetching and, later, WAL fetching/replaying happening.
1. By default, the instance of `n1-standard-8` type will be used. Such instances have quite weak disks because [Google throttles disk IO based on the disk size and the number of vCPUs](https://cloud.google.com/compute/docs/disks/performance#ssd-pd-performance)), but budget spending is low and risks to reach the GCE quotas for the "gitlab-restore" project are low. It is crucial to minimize the risks to reach those quotas because the daily backup verification jobs also use the "gitlab-restore" project. However, if your case is urgent and you need to perform PITR within a few hours, use `n1-highcpu-32`, specifying CI/CD variable `GCE_INSTANCE_TYPE` in the CI/CD pipeline launch interface. It is highly recommended to check the current resource consumption (total vCPUs, RAM, disk space, IP addresses, and the number of instances and disks in general) in the [GCP quotas interfaces of the "gitlab-restore" project](https://console.cloud.google.com/iam-admin/quotas?project=gitlab-restore).
1. Finally, especially if you have made multiple attempts to provision an instance via CI/CD Pipelines interface, check [VM Instances](https://console.cloud.google.com/compute/instances?project=gitlab-restore&instancessize=50) in GCP console to ensure that there are no stalled instances related to your work. If there are some, delete them manually.

After the process completes, an instance with a full GitLab installation and a production copy of the database is available for the next steps.

#### Extract meta data necessary to recover from file servers

Typically, we're interested in locating project meta data in the `projects` table like `repository_storage` and `disk_path` to help with the file server recovery.

#### Export project from database backup and import into GitLab

Here, we use the restored database instance with a GitLab install to export the project through the standard import/export mechanism. We want to avoid starting a full GitLab instance (to perform the export throughout the UI) because this sits on a full-sized production database. Instead, we use a rails console to trigger the export.

1. Start Redis: `gitlab-ctl start redis` (Redis is not going to be used really, but it's a required dependency)
2. Start Rails: `gitlab-rails c`

It is recommended to use a user with admin permission to export and import the projects. This helps to retain user associations with issues and comments made, for example.

```ruby
current_user = User.find_by(username: 'some-admin')
project = Project.find(1) # project id here
pts = Gitlab::ImportExport::ProjectTreeSaver.new(project: project, current_user: current_user, shared: project.import_export_shared)
pts.save
```

Take note of the path to a `project.json` file that the `ProjectTreeSave` reports. Download this file.

Now we wrap this into a `.tar.gz` file along with some example data by [grabbing the stub](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/spec/features/projects/import_export/test_project_export.tar.gz) `.tar.gz` and wrapping `project.json` inside it (unpack, pack).

The resulting `.tar.gz` archive can be restored through the GitLab UI or on the [command line](https://gitlab.com/gitlab-com/gl-infra/infrastructure/blob/master/.gitlab/issue_templates/import.md) (of the actual GitLab instance).

### File Data
* We need multiple things to help perform the restoration of data for a repo:
  1. The storage server the data was previously living on
  1. The full path of where the database thought the data was at
  1. The last known good date and time stamp of when the data was available

#### Retrieving This information
##### If the Project is **NOT** in GitLab
* If a project has been removed entirely from our database, it'll be difficult
  to get the above information. The information needs to be recovered from a database backup, see Database part above.

##### If the project is in GitLab
* These items can be found by issuing the following:
  1. `Project.find(<PROJECTID>).repository_storage`
  1. `Project.find(<PROJECTID>).disk_path`
* At this point we can log into that file server, browse to this location and
  see if the repo and wiki data might still exist.  If our cleanup process has
  cleaned them up, we'll now need to perform a restoration from backup.  See
  further details below
  * If our regular cleanup process hasn't removed the repos yet, you'll see them
    on disk as `<repository disk path>+deleted+<some time stamp>.git`
  * We can simply move them to the location specified by our database to put the
    data back in the correct location for GitLab to work properly
  * This must be done for both git repo and the wiki

#### Restoring from Disk Snapshot
* Using the timestamp provided, browse available Disk Snapshots in the Google
  Compute Console.
* Find the latest previous for the correct file server in relation to the known
  timestamp
* Use that snapshot to create a disk
* Mount that disk to an appropriate server
* Log into this server, mount the disk and browse to the location on disk where
  the git repo and wiki should live
* Create a tarball of each of these, move these tarballs to a secondary safe
  location
* Remove the file mount, unmount the disk from the server in the GCP console
* Delete the created disk
* Proceed to restore the data to the original file server in the correct
  location
* Ensure the data maintains proper ownership `git:root`

## Questions to Ask for coordination
* Will the project be restored to it's original place in GitLab?
  * Would the project ID's change? A export/import process like we describe above would generally generate a new project id.
  * Answering this question will impact the storage location on disk the repo
    will live
