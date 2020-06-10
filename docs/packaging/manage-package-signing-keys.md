# GPG Keys for Package Signing

As described in the [omnibus project for GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/package-information/signed_packages.md),
GitLab, Inc. provides signed packages starting with the release of `9.5`, and
all packages on stable trees from that point forward as well (e.g. `9.3.x` as
of August 22, 2017). The package signing keys are managed by the
[Distribution Team](https://about.gitlab.com/handbook/engineering/development/enablement/distribution/),
with the [Security Team](https://about.gitlab.com/handbook/security/#contact-gitlab-security)
over seeing and verifying that the best practices are followed.

The notes contained here are intended to provide documentation on how keys are generated, maintained, revoked, and used in combination with the Omnibus GitLab CI & PackageCloud.

## Usage of the keys

For a complete implementation, the following will be done:
* Generate and Securely store the private keys
* Publish the public keys
  * To a public PGP key server, such as `pgp.mit.edu`
  * All associated PackageCloud repositories on `packages.gitlab.com` but *only* once all related items are in place:
    * Package signing in CI on all supported stable branches.
    * Documentation for activation and verification.
* Publicly post about addition of the signing, and how to activate on existing installations. Provide links to the documentation on activation and verification.

## Location of the Key

The Omnibus package signing key is kept in an S3 bucket called `omnibus-sig`.
This bucket is attached to the `Gitlabdotcom` AWS account (#855 262 394 183).

## Securing Keys

Managing private keys follows the best practice of Least Privileged Access, and
access to the storage location and passphrase itself is highly restricted. These
two items _should never_ be stored together.

* There is a private, highly restricted location for the key itself to be stored.
* There is a private, highly restricted vault for the key's passphrase to be stored.
* **Security** team does the actual maintenance tasks related to the key(s) to ensure separation of concerns and LPA.
* The related variables in the `dev.gitlab.com` CI jobs should be marked as private, protected, and **never** be replicated.

## Generating the GPG Keys Pair

In the GPG key system, you generate a key pair, Public and Private. The public key will be posted to [packages.gitlab.com](https://packages.gitlab.com), and [pgp.mit.edu](https://pgp.mit.edu) or another public key server.

The private key content should be kept secret, with restricted access. The passphrase for this key should be kept separately, and maintained in a Vault with restricted access.

The following sections explain how to create and manage the keys.


### Ensuring Entropy

#### Linux

To properly secure they key generation process, one should do their best to provide extensive amounts entropy on their system. We'll cover how to do so on `Linux`.

- We're **requiring** physical hardware. **Absolutely** *No virtualized instances.*
- Check for access to a hardware random number generator (`hwrng`), `ls /dev/hwrng`
    - Check loaded kernel modules for `rng` or random number generator. `lsmod | grep rng`. This should output something akin to the following:

    ```
    tpm_rng                16384  0
    rng_core               16384  2 tpm_rng
    tpm                    40960  5 tpm_tis,trusted,tpm_crb,tpm_rng,tpm_tis_core
    ```

  - What we're looking for is a hardware random source, such as the `tpm`, beyond just `rng_core`. This may be: `intel-rng`, `amd-rng`, `tpm-rng`, even `bcm2708-rng`
  - If there are no modules other than `rng_core` present, then it is likely that you do not have a hardware random generator, or it is not active.
  - Depending on compute hardware, you may have a TPM, but is not active. If the hardware has it, attempt to load the module with `sudo modprobe tpm-rng`, and check `ls /dev/tpm*` and `ls /dev/hwrng` again.
  - If you do have a `hwrng`, this will need to be activated & tied to the [CSPRNG][] thanks to `rngd` daemon. This is often provided by the `rng-tools` packages, and should be started before continuing.
- If the hardware does not have a hardware RNG, we'll want to provide extra entropy by creating a lot of extra input/output to feed the [CSPRNG][] in the kernel.
  - Install and activate [`haveged`](http://www.issihosts.com/haveged/)
  - Be prepared to run a few tasks in the background (using screen, or backgrounding a call)
    - `dd if=/dev/<largedisk> of=/dev/null bs=1M` will generate extensive amounts of disk read IO, while not impacting any other subsystems.
    - `iperf` command can be used to create network load.

#### OSX

On a physical OSX machine (**not a virtualized instance**) it is best
to copy a couple of random files to `/dev/random` to insure that there
is enough entropy in the system. It is best to use files that are unique
and not generally available. Two to three moderate sized files are sufficient
to increase the entropy.

### Generate the keys

To generate a key pair, a user will need [GnuPG](https://www.gnupg.org), preferably but not required to be version `2.1` or greater.

The following information will need to be provided when generating a key.
- `kind of key you want`, which will be `(1) RSA and RSA`
- `keysize`, which will be `4096`, _not the default of `2048`_
- `how long the key is valid for`, which will be `2y` for 2 years.
- `Real Name`, which will be `GitLab, Inc.`
- `Email Address`, which will be `support@gitlab.com`
- `Comment`, which will be _an empty value_, `''`

Run `gpg --full-generate-key`, and provide values as above. You will be prompted for a passphrase, which should be an alpha-numeric combination that is 20+ characters long, such as generated by `1Password`.

The result of the above, should result in a brand new key pair, visible as such

```
$ gpg -k support@gitlab.com
pub   rsa2048 2017-07-26 [SC] [expires: 2022-07-26]
      0000000000000000000000000000000000000000
uid           [ultimate] GitLab, Inc. <support@gitlab.com>
sub   rsa2048 2017-07-26 [E] [expires: 2022-07-26]
```

_Note: the key id is masked here, as `0000000000000000000000000000000000000000`_

### Export the Keys

Once the keys have been generated, you will need to create a public key for
publishing, and in PackageCloud. This is completed simply via:

`gpg --armor --export <KEYID> > package-sig.gpg`

Next, we'll to export the entire secret key:

`gpg --export-secret-key <KEYID> > packages.gitlab.gpg`

This key should be uploaded to the secure storage location.

### Extending Key Expiration

By "extending" keys, we're actually referring to extending the `expire` field into the future, thus extending the useful lifespan of the key(s). To extend the signing key pair, one needs access to the original private key and passphrase.

The steps to extend are as follows:
- Import the original private key, as this should *never* be kept on a system.

  `gpg --allow-secret-key-import --import packages.gitlab.gpg`
- Confirm the key is imported and accessible with the private key:

  `gpg -k support@gitlab.com`
- Edit the key interactively with `gpg`:

  `gpg --edit-key <KEYID>`
- Enter `expire`, follow prompts to expire by X years with `2y`
- At this stage, you will be prompted to the key's passphrase.
- Enter `key 1` to select the subkey
- Enter `expire`, follow prompts to expire by X years with `2y`
- Enter `save` to store the changes to the key and exit.
- Export the updated key(s), and upload to appropriate storage locations & systems.
- Ensure to copy the original key to a backup file in the secure storage location.

See [Exporting the Keys]()

Citing from [gpg-announce in 2009'Q1](http://lists.gnupg.org/pipermail/gnupg-announce/2009q1/000282.html) :

> "Anytime you have a key expiring, it is a good time to ask yourself whether
> it's time to create a new key or extend the life of the old one. Good reasons
> to create a new key include using larger key size. Good reasons to continue
> using your existing key include keeping the signatures on the key so that any
> trust you've built up by others signing your key remains."

### Purging local copies!

Once one has completed any step here, and have **_safely uploaded to secure
storage_**, it is **very important** that they then **purge** the signing keys off their system.

`gpg --delete-secret-key <KEYID>`

## Reference material
- [http://irtfweb.ifa.hawaii.edu/~lockhart/gpg/]()
- [http://blog.jonliv.es/blog/2011/04/26/creating-your-own-signed-apt-repository-and-debian-packages/]()
- [https://www.2uo.de/myths-about-urandom/]()
- [http://cromwell-intl.com/linux/dev-random.html]()
- [https://www.gnupg.org/faq/gnupg-faq.html#new_key_after_generation]()
- [https://www.gnupg.org/gph/en/manual/c235.html#AEN328]()
- [https://riseup.net/en/security/message-security/openpgp/best-practices]()

[CSPRNG]: https://en.wikipedia.org/wiki/Cryptographically_secure_pseudorandom_number_generator
