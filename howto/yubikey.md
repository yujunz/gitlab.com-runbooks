# Configuring and Using the Yubikey

## Requirements
* `gpg2`
* `yubikey-personalization`

For this guide, when using linux, substitute `gpg` with `gpg2`

Make sure your Yubikey is inserted - and let's get ready to have some fun!

Let's set the module to behave like we want:
```
ykpersonalize -m86
```
This setting lets us use the Yubikey as both a SmartCard and an OTP device
at the same time.

**Note:** The above command is not necessary on a YubiKey 5 (and won't work)

## Changing the Default PIN Entries on the Yubikey PIV Card
By default the user PIN is `123456` and the ADMIN PIN is `12345678`, keep this
in mind when changing the PINS when it asks for the current PIN

```
> gpg --card-edit

Application ID ...: D2760001240102000006123482780000
Version ..........: 2.1
Manufacturer .....: Yubico
Serial number ....: 12345678
Name of cardholder: [not set]
Language prefs ...: [not set]
Sex ..............: unspecified
URL of public key : [not set]
Login data .......: [not set]
Signature PIN ....: not forced
Key attributes ...: [none]
Max. PIN lengths .: 127 127 127
PIN retry counter : 3 3 3
Signature counter : 2
Signature key ....: [none]
Encryption key....: [none]
Authentication key: [none]
General key info..: [none]

gpg/card> admin
Admin commands are allowed

# Change the PIN and Admin PINs
gpg/card> passwd
gpg: OpenPGP card no. D2760001240102000006123482780000 detected

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit

Your selection? 1
PIN changed.

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit

Your selection? 3
PIN changed.

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit

Your selection? q

# Make sure the PIN is entered before signing
gpg/card> forcesig

gpg/card> quit
```

## Master Key Storage

We want to keep the master key offline, encrypted, and stored in a super-secret-hiding-place.
We'll facilitate this by creating an encrypted portable drive on a USB drive.
For the purpose of this tutorial our USB drive will be called 'transit' and our
encrypted volume will be called 'GitLab'.

First we create an encrypted sparse bundle:
```
hdiutil create -fs HFS+ -layout GPTSPUD -type SPARSEBUNDLE -encryption AES-256 -volname "GitLab" -size 100m -stdinpass /Volumes/transit/gitlab.sparsebundle
```

Then we mount it up:
```
hdiutil attach -encryption -stdinpass -mountpoint /Volumes/GitLab /Volumes/transit/gitlab.sparsebundle
```

Create the configuration directory where our GnuPG key rings will live:

```
mkdir /Volumes/GitLab/gpg_config
chmod 700 /Volumes/GitLab/gpg_config
```

Export the configuration directory for GnuPG usage:

```
export GNUPGHOME=/Volumes/GitLab/gpg_config
```

Setup the `gpg.conf` before we create things:

```
echo default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAMELLIA256 CAMELLIA192 CAMELLIA128 TWOFISH >> /Volumes/GitLab/gpg_config/gpg.conf
echo cert-digest-algo SHA512 >> /Volumes/GitLab/gpg_config/gpg.conf
echo use-agent >> /Volumes/GitLab/gpg_config/gpg.conf
```

## Master Key Creation

```
> gpg --expert --full-generate-key
Please select what kind of key you want:
   (1) RSA and RSA (default)
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
   (7) DSA (set your own capabilities)
   (8) RSA (set your own capabilities)
Your selection? 8

Possible actions for a RSA key: Sign Certify Encrypt Authenticate
Current allowed actions: Sign Certify Encrypt

   (S) Toggle the sign capability
   (E) Toggle the encrypt capability
   (A) Toggle the authenticate capability
   (Q) Finished 

Your selection? s
Your selection? e
Your selection? q

RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (2048) 4096
Requested keysize is 4096 bits
Please specify how long the key should be valid.
         0 = key does not expire
        = key expires in n days
      w = key expires in n weeks
      m = key expires in n months
      y = key expires in n years
Key is valid for? (0) 4y
Key expires at Wed 25 Aug 2021 01:45:54 AM CST
Is this correct? (y/N) y

GnuPG needs to construct a user ID to identify your key.

Real name: John Rando
Email address: rando@gitlab.com
Comment:
You selected this USER-ID:
    "John Rando <rando@gitlab.com>"

Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? o

public and secret key created and signed.
pub   4096R/FAEFD83E 2017-08-25 [expires: 2021-08-25]
      Key fingerprint = 856B 1E1C FAD0 1FE4 5C4C  4E97 961F 703D B8EF B59D
uid                  John Rando <rando@gitlab.com>
```

Now that we have a master key, a good practice is to generate a revocation 
certificate in the event that we lose the password or the key is compromised.

**Note:** In some versions you do not see the key id in the gpg output. You can use your email here.

```
> gpg --gen-revoke FAEFD83E > /Volumes/GitLab/gpg_config/FAEFD83E-revocation-certificate.asc

Create a revocation certificate for this key? (y/N) y
Please select the reason for the revocation:
  0 = No reason specified
  1 = Key has been compromised
  2 = Key is superseded
  3 = Key is no longer used
  Q = Cancel
(Probably you want to select 1 here)
Your decision? 3
Enter an optional description; end it with an empty line:
> Using revocation certificate that was generated when key FAEFD83E was
> first created.  It is very likely that I have lost access to the
> private key.
> 
Reason for revocation: Key is no longer used
Using revocation certificate that was generated when key B8EFD59D was
first created.  It is very likely that I have lost access to the
private key.
Is this okay? (y/N) y

ASCII armored output forced.
Revocation certificate created.

Please move it to a medium which you can hide away; if Mallory gets
access to this certificate he can use it to make your key unusable.
It is smart to print this certificate and store it away, just in case
your media become unreadable.  But have some caution:  The print system of
your machine might store the data and make it available to others!
```

## Generating Subkeys
We'll use subkeys that are generated on the Yubikey device itself. Keys generated
on the Yubikey cannot be copied off, so loss or destruction of the device will 
mean key rotation.

```
> gpg --edit-key FAEFD83E

# Let's add the SIGNING subkey
gpg> addcardkey

 Signature key ....: [none]
 Encryption key....: [none]
 Authentication key: [none]

Please select the type of key to generate:
   (1) Signature key
   (2) Encryption key
   (3) Authentication key
Your selection? 1

Please specify how long the key should be valid.
         0 = key does not expire
        = key expires in n days
      w = key expires in n weeks
      m = key expires in n months
      y = key expires in n years
Key is valid for? (0) 1y
Key expires at Sat Aug  25 01:08:14 2018 CST
Is this correct? (y/N) y
Really create? (y/N) y  

pub  3072R/FAEFD83E  created: 2017-08-25  expires: 2018-08-25  usage: C
                     trust: ultimate      validity: ultimate
sub  4096R/79BF274F  created: 2017-08-25  expires: 2018-08-25  usage: S
[ultimate] (1). John Rando <rando@gitlab.com>

# Do the same for the ENCRYPTION subkey
gpg> addcardkey

 Signature key ....: 546D 6A7E EB4B 5B07 B3EA  7373 12E2 68AD 79BF 574F
 Encryption key....: [none]
 Authentication key: [none]

Please select the type of key to generate:
   (1) Signature key
   (2) Encryption key
   (3) Authentication key
Your selection? 2

Please specify how long the key should be valid.
         0 = key does not expire
        = key expires in n days
      w = key expires in n weeks
      m = key expires in n months
      y = key expires in n years
Key is valid for? (0) 1y
Key expires at Sat Aug  25 01:10:41 2018 CST
Is this correct? (y/N) y
Really create? (y/N) y  

pub  4096R/FAEFD83E  created: 2017-08-25  expires: 2018-08-25  usage: C
                     trust: ultimate      validity: ultimate
sub  4096R/AE86E89B  created: 2017-08-25  expires: 2018-08-25  usage: E
sub  4096R/79BF274F  created: 2017-08-25  expires: 2018-08-25  usage: S
[ultimate] (1). John Rando <rando@gitlab.com>

# Do the same for the AUTHENTICATION subkey
gpg> addcardkey

 Signature key ....: 546D 6A7E EB4B 5B07 B3EA  7373 12E2 68AD 79BF 574F
 Encryption key....: [none]
 Authentication key: [none]

Please select the type of key to generate:
   (1) Signature key
   (2) Encryption key
   (3) Authentication key
Your selection? 3

Please specify how long the key should be valid.
         0 = key does not expire
        = key expires in n days
      w = key expires in n weeks
      m = key expires in n months
      y = key expires in n years
Key is valid for? (0) 1y
Key expires at Sat Aug  25 01:21:41 2018 CST
Is this correct? (y/N) y
Really create? (y/N) y

pub  4096R/FAEFD83E  created: 2017-08-25  expires: 2018-08-25  usage: C
                     trust: ultimate      validity: ultimate
sub  4096R/AE86E89B  created: 2017-08-25  expires: 2018-08-25  usage: E
sub  4096R/79BF274F  created: 2017-08-25  expires: 2018-08-25  usage: S
sub  4096R/DE86E396  created: 2017-08-25  expires: 2018-08-25  usage: A
[ultimate] (1). John Rando <rando@gitlab.com>
```

## Backup and Publish your Public Key
```
> gpg --armor --export FAEFD83E > /Volumes/GitLab/gpg_config/FAEFD83E.asc
```

If your gpg version does not output the key id you should use the full fingerprint instead.
```
> gpg --keyserver hkps://hkps.pool.sks-keyservers.net --send-key FAEFD83E
```

## Generate your SSH Public Key
```
> gpg --export-ssh-key FAEFD87E
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABA ... COMMENT
```

## Import Public Key to Regular Keychain

Open up the GPG Keychain app and import the public key that you just created
into your regular keychain. Set the Ownertrust to Ultimate on the public key
you've imported.

Or in a fresh terminal we can:
```
> gpg --import /Volumes/GitLab/gpg_config/FAEFD83E.asc
gpg: key FAEFD83E: public key imported
gpg: Total number processed: 1
gpg:               imported: 1

> gpg --edit-key FAEFD83E
Secret subkeys are available.

pub  4096R/FAEFD83E  created: 2017-08-25  expires: 2018-08-25  usage: C
                     trust: ultimate      validity: ultimate
sub  4096R/AE86E89B  created: 2017-08-25  expires: 2018-08-25  usage: E
sub  4096R/79BF274F  created: 2017-08-25  expires: 2018-08-25  usage: S
sub  4096R/DE86E396  created: 2017-08-25  expires: 2018-08-25  usage: A
[ultimate] (1). John Rando <rando@gitlab.com>

gpg> trust
pub  4096R/FAEFD83E  created: 2017-08-25  expires: 2018-08-25  usage: C
                     trust: ultimate      validity: ultimate
sub  4096R/AE86E89B  created: 2017-08-25  expires: 2018-08-25  usage: E
sub  4096R/79BF274F  created: 2017-08-25  expires: 2018-08-25  usage: S
sub  4096R/DE86E396  created: 2017-08-25  expires: 2018-08-25  usage: A
[ultimate] (1). John Rando <rando@gitlab.com>

Please decide how far you trust this user to correctly verify other users' keys
(by looking at passports, checking fingerprints from different sources, etc.)

  1 = I don't know or won't say
  2 = I do NOT trust
  3 = I trust marginally
  4 = I trust fully
  5 = I trust ultimately
  m = back to the main menu

Your decision? 5
Do you really want to set this key to ultimate trust? (y/N) y
gpg> quit
```

## Ensure proper options are set in gpg-agent.conf

Your `gpg-agent.conf` should look something **like** 

```
$ cat ~/.gnupg/gpg-agent.conf
default-cache-ttl 600
max-cache-ttl 7200
pinentry-program /usr/local/bin/pinentry-mac
enable-ssh-support
```

## Ensure your environment knows how to authenticate SSH
* Insert one of the following into your `rc` file

* On OSX you'll need this:
```
export SSH_AUTH_SOCK=$HOME/.gnupg/S.gpg-agent.ssh
```

* On Linux you'll need this:
```
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
```

## Script to Reset gpg-agent and ssh-agent

On OSX, use this script will reset `gpg-agent` and `ssh-agent` after you make the
above updates to `gpg-agent.conf`.

```
#!/bin/bash

echo "kill gpg-agent"
code=0
while [ 1 -ne $code ]; do
    killall gpg-agent
    code=$?
    sleep 1
done

echo "kill ssh"
    killall ssh

echo "kill ssh muxers"
    for pid in `ps -ef | grep ssh | grep -v grep | awk '{print $2}'`; do
    kill $pid
done

echo "restart gpg-agent"
    eval $(gpg-agent --daemon)

echo
echo "All done. Now unplug / replug the NEO token."
echo
```

On Linux modify the `gpg-agent` with the following: `gpgconf --launch gpg-agent`

## Personal Cleanup
* If you have anything inside of your own dot files or system configuration that
  may startup the ssh-agent, disable it
* If you have anything that starts up the `gpg-agent`, ensure the options reflect
  the work we've accomplished above
* A good short test to validate all is well, when adding ssh keys (such as your
  git ssh key), should work just fine, as well as a listing `ssh-add -l`

## Reference Material
* https://github.com/drduh/YubiKey-Guide#21-install---linux
