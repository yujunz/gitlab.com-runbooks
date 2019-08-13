# Deleting a project manually

Sometimes projects are not completely deleted due to [postgres statement timeouts](https://gitlab.com/gitlab-org/gitlab-ce/issues/52517) and can end up in a half-deleted state where it cannot be deleted via the admin dashboard.

### Preparation

1. You will need to know the ID or path of the project. For example, the path for the runbooks project `https://gitlab.com/gitlab-com/runbooks` will be `gitlab-com/runbooks`.
1. You will need a user id or username that has the ability to delete a project, such as the user that created the project or an admin on GitLab.com.

### Steps

1. Start a rails console issuing the command `sudo gitlab-rails console`.
1. Verify that the delete error is due to a hitting a database timeout. `PG::QueryCanceled: ERROR:  canceling statement due to statement timeout`. You can do this like so :

    ```ruby
    Project.find_by_full_path('path/to/project').delete_error
    => "PG::QueryCanceled: ERROR:  canceling statement due to statement timeout\nCONTEXT:  SQL statement \"DELETE FROM ONLY \"public\".\"merge_request_diff_files\" WHERE $1 OPERATOR(pg_catalog.=) \"merge_request_diff_id\"\"\n: DELETE FROM \"projects\" WHERE \"projects\".\"id\" = 12345"
    ```
1. Fetch the username and project:

    ```ruby
    user = User.find_by_username('user-or-admin-username-goes-here')
    proj = Project.find_by_full_path('path/to/project')

    # Alternatively, if you only have the IDs
    user = User.find(55555)
    proj = Project.find(12345)
    ```

1. Destroy the project's dependent associations. This might take a while if they have a lot of pipelines or artifacts. You can do this with:

    ```ruby
    Rails.logger.level = 0
    proj.destroy_dependent_associations_in_batches(exclude: [:container_repositories]);nil
    ```

1.  Attempt to delete the project via the `DestroyService` to clean up the rest of the project such as the wiki, registry images, etc. You may need to run this more than once if you encounter a statement timeout (it will return false):

    ```ruby
    Projects::DestroyService.new(proj, user, {}).execute
    => true
    ```

1. Verify the project no longer exists:

    ```ruby
    proj = Project.find_by_full_path('path/to/project')
    => nil

    # Alternatively, if you only have the ID
    proj = Project.find(12345)
    => nil
    ```
