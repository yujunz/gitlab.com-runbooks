## GSTG bastion hosts

##### How to start using them
Add the following to your `~/.ssh/config` (specify your username and path to ssh private key):
```
# GCP staging bastion host
Host lb-bastion.gstg.gitlab.com
        User                            YOUR_SSH_USERNAME
        IdentityFile                    /path/to/your/ssh/key

# gstg boxes
Host *.gitlab-staging-1.internal
        PreferredAuthentications        publickey
        IdentityFile                    /path/to/your/ssh/key
        ProxyCommand                    ssh lb-bastion.gstg.gitlab.com -W %h:%p
```

Testing (for example, if you have access to deploy node), output should be like this:
```bash
$> be knife ssh 'roles:gstg-base-deploy-node' 'hostname'
deploy-01-sv-gstg.c.gitlab-staging-1.internal deploy-01-sv-gstg
```
##### Console access

There is a dedicated server for console access named
`console-01-sv-gstg.c.gitlab-staging-1.internal`

You can create the following entry in your ssh config for easier access

```
Host gstg-console
        StrictHostKeyChecking   no
        HostName                console-01-sv-gstg.c.gitlab-staging-1.internal
        ProxyCommand            ssh lb-bastion.gstg.gitlab.com -W %h:%p
```

See [granting rails or db access](granting-rails-or-db-access.md) for more
information on how to request console access.

##### Host keys
If you care about security enough to compare ssh host keys, here they are, both sha256 and md5 sums:
```
$> ssh-keygen -lf <(ssh-keyscan lb-bastion.gstg.gitlab.com 2>/dev/null)
256 SHA256:HAPLsO33HVEaV4LgRRD7SnhMQOwroBVOQvlaUFxzFsM lb-bastion.gstg.gitlab.com (ECDSA)
2048 SHA256:SM4BmyWO/y3MNgJVYsDcWJVBX41ouyNznv8gkUF3pI8 lb-bastion.gstg.gitlab.com (RSA)
256 SHA256:hPfler9kdTjPGX8xFtgLiEJC8iozBIZSkc3JM1WKNKc lb-bastion.gstg.gitlab.com (ED25519)

$> ssh-keygen -E md5 -lf <(ssh-keyscan lb-bastion.gstg.gitlab.com 2>/dev/null)
2048 MD5:c3:ca:b9:85:34:ec:60:2c:59:b2:d2:e4:ef:07:a5:b0 lb-bastion.gstg.gitlab.com (RSA)
256 MD5:79:6b:1e:5c:8a:4f:13:db:e0:1d:26:73:20:6f:cd:11 lb-bastion.gstg.gitlab.com (ECDSA)
256 MD5:08:bc:a7:52:60:25:bc:65:13:96:d7:44:be:11:d9:40 lb-bastion.gstg.gitlab.com (ED25519)
```

##### Tunnel https traffic

gstg public https access is [blocked](https://gitlab.com/gitlab-com/migration/issues/509).
Therefore to connect to gstg, you'll need to set up a tunnel.

To set up such a tunnel:

1. Open a tunnel SSH session:

    ```sh
    ssh -L 8443:fe-01-lb-gstg.c.gitlab-production.internal:443 lb-bastion.gstg.gitlab.com
    ```

1. Visit gstg on localhost:

    ```sh
    open https://localhost:8443/users/sign_in
    ```

1. That works, although it causes a TLS certificate error due domain name mismatch. You can ignore this, or add the following line to `/etc/hosts`:

    ```
    127.0.0.1       gstg.gitlab.com
    ```

    After that you can visit `https://gstg.gitlab.com:8443/users/sign_in`.

    **Caution:** Ensure to _remove_ this line again when the GCP migration is done (after blackout window).

1. _Pre-failover:_ Before the failover you'll need to log in on on gstg via OAuth on gitlab.com. This does not work with the above method,
   due to incorrect redirect URL. So instead, you can set up the tunnel as root, on port `443`:

    ```sh
    sudo ssh -F $HOME/.ssh/config -L 443:fe-01-lb-gstg.c.gitlab-production.internal:443 lb-bastion.gstg.gitlab.com
    ```

    Visiting `https://gstg.gitlab.com/users/sign_in` will now work as a charm.

##### Tunnel git-over-ssh traffic

Similar to setting up a tunnel for the https traffic, you can set up a
tunnel for git-over-ssh traffic:

1. Open a tunnel SSH session:

    ```sh
    sudo ssh -F $HOME/.ssh/config -L 22:fe-01-lb-gstg.c.gitlab-production.internal:22 lb-bastion.gstg.gitlab.com
    ```

1. Clone a repo:

    ```sh
    git clone git@localhost:gitlab-org/gitlab-ce.git
    ```

1. Or when you have `gstg.gitlab.com` to point to `127.0.0.1` in `/etc/hosts`:

    ```sh
    git clone git@gstg.gitlab.com:gitlab-org/gitlab-ce.git
    ```

1. _Pre-failover:_ When gstg is a Geo secondary, don't forget to set the push remote:

    ```sh
    git remote set-url --push origin git@gitlab.com:gitlab-org/gitlab-ce.git
    ```

##### Links
 1. [Issue](https://gitlab.com/gitlab-com/migration/issues/299) describing what was done in scope of the migration project to quickly set them up.
 1. [META](https://gitlab.com/gitlab-com/infrastructure/issues/3995) issue that is a source of truth regarding middleterm/longterm setup.
