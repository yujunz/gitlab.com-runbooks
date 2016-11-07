# Aptly

Our aptly server is aptly.gitlab.com and is primary used to mirror ceph repository but we can use it to mirror any other repository.

## Update a mirror

Currently we don't auto update any mirror since we need to manual sign the mirror when publishing.

### Update mirror

```
root@aptly:~# aptly mirror list
List of mirrors:
 * [ceph-jewel]: https://download.ceph.com/debian-jewel/ xenial

root@aptly:~# aptly mirror update ceph-jewel
Downloading https://download.ceph.com/debian-jewel/dists/xenial/InRelease...
gpgv: Signature made Mon 17 Oct 2016 12:42:02 PM UTC using RSA key ID 460F3994
gpgv: Good signature from "Ceph.com (release key) <security@ceph.com>"
Downloading & parsing package files...
Downloading https://download.ceph.com/debian-jewel/dists/xenial/main/binary-amd64/Packages.bz2...
Building download queue...
Download queue: 0 items (0 B)

Mirror `ceph-jewel` has been successfully updated.
```

### Create new snapshot

Just use current date in name so we know from when the repository was updated.

```
root@aptly:~# aptly snapshot create ceph-jewel-2016-11-07 from mirror ceph-jewel

Snapshot ceph-jewel-2016-11-07 successfully created.
```

### Switch published to new snapshot

The passphrase for the gpg key can be found in 1password in the devops vault.

```
root@aptly:~# aptly publish switch xenial ceph-jewel-2016-11-07
Loading packages...
Generating metadata files and linking package files...
Finalizing metadata files...
Signing file 'Release' with gpg, please enter your passphrase when prompted:

You need a passphrase to unlock the secret key for
user: "GitLab Infra <ops-notifications@gitlab.com>"
2048-bit RSA key, ID E4BDBB30, created 2016-10-27

gpg: gpg-agent is not available in this session
Clearsigning file 'Release' with gpg, please enter your passphrase when prompted:

You need a passphrase to unlock the secret key for
user: "GitLab Infra <ops-notifications@gitlab.com>"
2048-bit RSA key, ID E4BDBB30, created 2016-10-27

gpg: gpg-agent is not available in this session
Cleaning up prefix "." components main...

Publish for snapshot ./xenial [amd64] publishes {main: [ceph-jewel-2016-11-07]: Snapshot from mirror [ceph-jewel]: https://download.ceph.com/debian-jewel/ xenial} has been successfully switched to new snapshot.
```

