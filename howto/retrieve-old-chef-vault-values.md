# Retrieving old Chef Vault values

If someone makes a change in an encrypted data bag, you may need to restore
the old value. For example, if the public key of GitLab Pages is changed
without updating the private key, you may need to retrieve the old value.

Fortunately, the chef-repo directory contains version-controlled encrypted
data in the data_bags directory. We can use use this to our advantage.

## How to retrieve old data

For example, let's say you want to see the data at commit
a8a60325c16ceabf5ed50d5b241fa470c478b7bf. Here's the quick playbook:

1. Check out the version of chef-repo that you want:

    ```
    git checkout a8a60325c16ceabf5ed50d5b241fa470c478b7bf
    ```

1. Upload all the data bags to your LOCAL chef installation.
    **BE SURE TO INCLUDE THE -z OPTION TO OPERATE IN LOCAL MODE**:

    ```
    knife data bag from file -a -z
    ```

1. Retrieve the data via `chef vault`. Note the -z option again:

    ```
    knife vault show <role> <values> -z
    ```

    For example:

    ```
    knife vault show gitlab-cluster-base _default -z
    ```

## Verifying SSL public/private keys

Once you have the public and private keys, you can verify that they match:

    ```
    openssl x509 -noout -modulus -in certificate.crt | openssl md5
    openssl rsa -noout -modulus -in privateKey.key | openssl md5
    ```
