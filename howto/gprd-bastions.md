## GPRD bastion hosts

##### How to start using them
Add the following to your `~/.ssh/config` (specify your username and path to ssh private key):
```
# GCP production bastion host
Host lb-bastion.gprd.gitlab.com
        User                            YOUR_SSH_USERNAME
        IdentityFile                    /path/to/your/ssh/key

# gprd boxes
Host *.gitlab-production.internal
        User                            YOUR_SSH_USERNAME
        PreferredAuthentications        publickey
        IdentityFile                    /path/to/your/ssh/key
        ProxyCommand                    ssh lb-bastion.gprd.gitlab.com -W %h:%p
```

Testing (for example, if you have access to deploy node), output should be like this:
```bash
$> be knife ssh 'roles:gprd-base-deploy-node' 'hostname'
deploy-01-sv-gprd.c.gitlab-production.internal deploy-01-sv-gprd
```
##### Console access

There is a dedicated server for console access named
`console-01-sv-gprd.c.gitlab-production.internal`

You can create the following entry in your ssh config for easier access

```
Host gprd-console
    HostName console-01-sv-gprd.c.gitlab-production.internal
```
See [granting rails or db access](granting-rails-or-db-access.md) for more
information on how to request console access.

##### Host keys
If you care about security enough to compare ssh host keys, here they are, both sha256 and md5 sums:
```
$> ssh-keygen -lf <(ssh-keyscan lb-bastion.gprd.gitlab.com 2>/dev/null)
2048 SHA256:ygMvT9QHMoqxvUULMfvSyo/Lsbx6UEiKoLloFf/BSU0 lb-bastion.gprd.gitlab.com (RSA)
256 SHA256:YjrYlnAlbKv23MI+h4UJGaGU32SWHngXti2ahIEEVz0 lb-bastion.gprd.gitlab.com (ECDSA)
256 SHA256:AOtQEj7qZx3SPq61NU0vxDh9k0f+nccwZOO9ayTkVn8 lb-bastion.gprd.gitlab.com (ED25519)

$> ssh-keygen -E md5 -lf <(ssh-keyscan lb-bastion.gprd.gitlab.com 2>/dev/null)
256 MD5:f7:b3:0c:e1:84:9d:28:1d:6d:84:ff:31:72:56:62:2d lb-bastion.gprd.gitlab.com (ECDSA)
2048 MD5:f4:53:0d:0c:c8:ec:ee:11:18:7a:cc:3a:20:fb:7a:70 lb-bastion.gprd.gitlab.com (RSA)
256 MD5:ab:2b:c8:a7:48:b6:67:1a:cb:94:b0:a3:3f:d6:a0:b3 lb-bastion.gprd.gitlab.com (ED25519)
```

##### Links
 1. [Issue](https://gitlab.com/gitlab-com/migration/issues/299) describing what was done in scope of the migration project to quickly set them up.
 1. [META](https://gitlab.com/gitlab-com/infrastructure/issues/3995) issue that is a source of truth regarding middleterm/longterm setup.
