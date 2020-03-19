# Geo Migration

## Recovering a repo from Azure

Suppose project `foo/bar` is missing. In GPRD, find where the repo lives:

1. In a Rails console in GPRD (`sudo gitlab-rails c`):

    ```ruby
    Project.find_by_full_path('foo/bar').repository.path
    => "/var/opt/gitlab/git-data-file18/repositories/foo/bar.git"

2. Go into the main directory and create a tarball:

    ```sh
    cd /var/opt/gitlab/git-data-file18/repositories/foo
    tar cvf /tmp/foo-bar.tar bar.*git
    ```

3. Copy this tarball into GPRD.

4. Untar this into the right place:

    ```sh
    cd /var/opt/gitlab/git-data-file18/repositories/foo
    tar xvf /tmp/foo-bar.tar
    ```

5. In the Rails console in GPRD, expire the caches:

    ```ruby
    Project.find_by_full_path('foo/bar').repository.expire_all_method_caches
    ```
