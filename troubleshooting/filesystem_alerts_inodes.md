## Symptoms

You're likely here because you saw a message saying Free inodes on __host__ on __path__ is at __very low number__".

## Troubleshooting

Usually due to a large number of files, check the filesystem file count with the following command on the host:

```
sudo find FS_PATH -xdev -printf '%h\n' | sort | uniq -c | sort -k 1 -n
```
