# Blocking a project causing high load

## Steps

1. Start a rails console issuing the command `sudo gitlab-rails console`.

1. Set the project in question to private. For example, `my-namespace/my-group/my-project` would be:

    ```ruby
    project = Project.find_by_full_path('my-namespace/my-group/my-project')
    project.visibility_level = Gitlab::VisibilityLevel::PRIVATE
    project.save
    ```

1. If that fails for some reason, navigate to the project via an admin
account and disable that. For example, the URL for the example above would be:

    https://gitlab.com/my-namespace/my-group/my-project/settings/edit

    Under `Permissions`, click `Expand`, and set `Project visibility` from `Public` to `Private`.

1. For good measure, you may also want to toggle the `Repository` button from on to off.

1. To avoid having these settings changed by the project owner, you may also
want to block the owner of the project. For example:

    ```ruby
    project.owner.block!
    ```
