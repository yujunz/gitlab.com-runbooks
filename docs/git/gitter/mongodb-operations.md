# How to enlarge MongoDB data volumes

Gitter's MongoDB data is stored on EBS volumes formatted with XFS. This combo means that we can resize a volume online, without even stopping the mongod process. This is how it's done.

  1. Increase the size of the EBS volume. You can safely ignore the warning messages about resizing it: we'll do this later. This process is the longest part of the operation. Just wait for the resize to complete.
  1. Once the volume has been successfully resized, log onto the MongoDB node that you want to resize and run `sudo xfs_growfs /var/lib/mongodb`.
  1. You're done. No, for real: you can log out and do something else.
