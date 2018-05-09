# "Stale file handle" errors on NFS mounts

## First and foremost

*Don't Panic*

## Symptoms

`chef-client` runs fail with a message like the following:

```
 * directory[/path/to/mountpoint] action create[2018-05-09T13:13:47+00:00] INFO: Processing directory[/path/to/mountpoint] action create (gitlab-nfs-cluster::client line 11)


    ================================================================================
    Error executing action `create` on resource 'directory[/path/to/mountpoint]'
    ================================================================================

    Errno::EEXIST
    -------------
    File exists @ dir_s_mkdir - /path/to/mountpoint
```

## Possible checks

To make sure the problem is stale file handles, attempt to `ls` the path. It
should generate an output like the following:

```
ls /path/to/mountpoint
ls: cannot access '/path/to/mountpoint': Stale file handle
```

## Resolution

Stale file handles are simply solved by remounting the affected path. If you can
afford it, the simpler way is to reboot the machine with something like:

```
echo "s" > /proc/sysrq-trigger # Attempts to sync disks attached to the system
echo "u" > /proc/sysrq-trigger # Attempts to unmount and remount all file systems as read-only
echo "b" > /proc/sysrq-trigger # Reboots the kernel without first unmounting file systems or syncing disks attached to the system.
```
