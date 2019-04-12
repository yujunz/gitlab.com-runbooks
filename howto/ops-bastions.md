## OPS bastion hosts

##### How to start using them
Add the following to your `~/.ssh/config` (specify your username and path to ssh private key):
```
# GCP staging bastion host
Host lb-bastion.ops.gitlab.com
        User                            YOUR_SSH_USERNAME

# gstg boxes
Host *.gitlab-ops.internal
        PreferredAuthentications        publickey
        ProxyCommand                    ssh lb-bastion.ops.gitlab.com -W %h:%p
```


##### Host keys
If you care about security enough to compare ssh host keys, here they are, both sha256 and md5 sums:
```
$> ssh-keygen -lf <(ssh-keyscan lb-bastion.ops.gitlab.com 2>/dev/null)
256 SHA256:YjrYlnAlbKv23MI+h4UJGaGU32SWHngXti2ahIEEVz0 lb-bastion.ops.gitlab.com (ECDSA)
2048 SHA256:ygMvT9QHMoqxvUULMfvSyo/Lsbx6UEiKoLloFf/BSU0 lb-bastion.ops.gitlab.com (RSA)
256 SHA256:AOtQEj7qZx3SPq61NU0vxDh9k0f+nccwZOO9ayTkVn8 lb-bastion.ops.gitlab.com (ED25519)

$> ssh-keygen -E md5 -lf <(ssh-keyscan lb-bastion.ops.gitlab.com 2>/dev/null)
2048 MD5:f4:53:0d:0c:c8:ec:ee:11:18:7a:cc:3a:20:fb:7a:70 lb-bastion.ops.gitlab.com (RSA)
256 MD5:f7:b3:0c:e1:84:9d:28:1d:6d:84:ff:31:72:56:62:2d lb-bastion.ops.gitlab.com (ECDSA)
256 MD5:ab:2b:c8:a7:48:b6:67:1a:cb:94:b0:a3:3f:d6:a0:b3 lb-bastion.ops.gitlab.com (ED25519)
```
