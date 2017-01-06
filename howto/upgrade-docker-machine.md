# Upgrade docker-machine

It sometimes becomes necessary to update docker-machine due to major changes
in docker or its API. The main indicator thus far that this needs to be done
has been a failure of machines to create. Monitoring for such a problem is
in the works.

## Steps

### Update Attributes

The first step is to update the attributes that control what version and checksum
are used to download and verify the docker-machine binary.

To view the secrets, run the rake task to show secrets. Please replace 
`omnibus-builder-runners-manager` in the below command with the role you are
attempting to update.

```
$ rake show_role_secrets [omnibus-builder-runners-manager,_default]
```

Next, we will need to actually get the information to update the attributes.
To do so, you will need to download the appropriate docker-machine binary and verify 
its checksum. 

```
$ cd /tmp
$ wget https://github.com/docker/machine/releases/download/v0.9.0-rc2/docker-machine-Linux-x86_64 -O docker-machine
$ chmod +x docker-machine
$ ./docker-machine version
docker-machine version 0.9.0-rc2, build 7b1959
$ sha256sum docker-machine
ff61c2f688778719b0ceb5a1062a3ae9f2a83daa06a1d4551b5f19a6432507db  docker-machine
```

Please note that at this time you will also need to update the source URL as something
is wrong with the cookbook.
Once we have this data we can update the attributes by using the following command.

```
$ rake edit_role_secrets[omnibus-builder-runners-manager,_default]
```

A commit message will be required for this command. Please use a descriptive message
about what has changed *and* why.

### Run chef-client

Now that all that has been done, you will need to actually log into the machine and
run `chef-client`. Once the run is complete, please verify that docker machine has indeed
been updated.

```
$ /usr/bin/docker-machine version
```

If it is correct, than all is well!
