
# Uploads #

## Intro ##

Search keywords: attachments, files

Uploads in production are stored in a GCS bucket: https://docs.gitlab.com/ee/administration/uploads.html#object-storage-settings

Here's an example of an upload URL: `https://gitlab.com/4dface/4dface-sdk/uploads/<secret>/image.png`

Upload objects in rails are defined here: `./gitlab-ce/app/models/upload.rb`

## Managing uploads (deleting, renaming, etc) ##

At the moment of writing there is no UI for managing uploads: https://gitlab.com/gitlab-org/gitlab-ce/issues/23553

Using the console, you can find the upload object in the rails application:
```ruby
u = Upload.find_by_secret("<secret>")
```

its path in GCS (the storage path consists of two hashes: storage hash and upload's secret):
```ruby
u.path
```

and delete the upload together with the file on GCS:
```ruby
u.destroy
```

or rename it:
```ruby
> u.secret = "<new GUID>"
> u.path  # this path consists of a hash and the upload's secret, it will be used in the next command
> u.path = "<path from previous command with upload's secret replaced with the newly generated secret>"
> u.save!
# move file in object storage manually to new path
```

## Example ##

URL of an upload that needs to be removed: https://gitlab.com/4dface/4dface-sdk/uploads/f7a123bb72bfa73a2d0cf9c12cab99e1/image.png

1. Get the upload's path on GCS:
```ruby
> u = Upload.find_by_secret("f7a123bb72bfa73a2d0cf9c12cab99e1")
> u.path
```

2. Check in GCS that the file is present

3. Remove the file from the rails app and GCS:
```ruby
Upload.find_by_secret("f7a123bb72bfa73a2d0cf9c12cab99e1").destroy
```

4. Check again on GCS that the file is gone


## Example issues ##

- Rename files in an issue: https://gitlab.com/gitlab-com/gl-infra/production/issues/887
- Delete an uploaded file: https://gitlab.com/gitlab-com/support/dotcom/dotcom-escalations/issues/116
