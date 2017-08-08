## Symptoms

You're likely here because you saw a message saying Free inodes on __host__ on __path__ is at __very low number__".

## Troubleshooting

Usually due to a large number of files, check the filesystem file count with the following command on the host:

```
sudo find FS_PATH -xdev -printf '%h\n' | sort | uniq -c | sort -k 1 -n
```

Quick overview of inode usage:

```
df -hi
```

## Likely suspects


#### Linux kernels and headers

We have `unattended-upgrades` enabled, which install the kernel updates.

But we don't automatically reboot into those, so they accumulate with
time. Relevant infrastructure [issue](https://gitlab.com/gitlab-com/infrastructure/issues/2435).

Since each `linux-kernel-X` package contains ~10^3 files, and each
`linux-headers-X` package contains ~10^4 files, they can eat up all the
inodes on the `/` partition pretty quickly. Here's the one-liner template
for removing all the 3.X and 4.X kernels and images except running one and
the latest one (replace LATEST with version, say, `4.4.0-89`)

```
dpkg -l | grep 'linux-\(headers\|image\)-[34]' | grep -v $(uname -r) | grep -v 'LATEST' | awk '{print $2}' | xargs apt-get -y purge
```
