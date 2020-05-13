# GCP Projects

## New Project Creation

The following assumes you want to utilize our existing infrastructure as much as
feasibly possible.  This includes the use of our existing terraform and chef
infrastructure.

The following documentation only covers what is required to bootstrap an
environment.  This includes what is necessary in terraform and GCP prior to
starting up your first instance in that project.  Details of what is created
inside of that project will not be discussed as that is implementation specific.

1. Follow the documentation here: https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/#creating-a-new-environment
    * This will build out the framework for the project and it's requirements
1. Create two service accounts in GCP:
    * `terraform`
    * `google-object-storage`
    1. Navigate to your new project
    1. Browse to `IAM` > `Service Accounts`
    1. Click `Create Service Account`
    1. Fill in the following fields with the same data for each account:
        * `Service account name`
        * `Service account ID`
        * `Service account description`
    1. When completed, on the main `Service Account` screen, you'll see your new
       account listed.
    1. Ensure the email address of the account is what is expected.  This is the
       format `<serviceAccountName>@<ENV>.iam.gserviceaccount.com`
1. Create the bootstrap Key ring framework
    1. Browse to `IAM` > `Cryptographic keys`
    1. Click `Create Key Ring`
    1. Utilize the name `gitlab-<ENV>-boostrap` - example `gitlab-pre-bootstrap`
        * This is required as our chef bootstrap script require this
          nomenclature
        * Utilize a `global` Key ring location
    1. Click `Create`
    1. On the next screen utilize these details:
       * `Generated Key`
       * `Key name`: `gitlab-<ENV>-bootstrap-validation`
       * Protection Level: `Software`
       * Purpose: `Symmetric encrypt/decrypt`
       * Rotation: `90 days`
       * Utilize the default rotation start date
    1. Click `Create`
1. Create the chef Key ring framework
    1. Browse to `IAM` > `Cryptographic keys`
    1. Click `Create Key Ring`
    1. Utilize the name `gitlab-secrets`
        * This is required as our chef bootstrap script require this
          nomenclature
        * Utilize a `global` Key ring location
    1. Click `Create`
    1. On the next screen utilize these details:
       * `Generated Key`
       * `Key name`: `<ENV>`
       * Protection Level: `Software`
       * Purpose: `Symmetric encrypt/decrypt`
       * Rotation: `90 days`
       * Utilize the default rotation start date
    1. Click `Create`
1. Provide the terraform service account permissions to the new key and keyring
    1. Perform the following on both keyrings created in the prior step
    1. Navigate to `IAM` > `Cryptographic Keys`
    1. Select our newly created Key Ring
    1. On the panel to the right click `Add Member`
    1. The new member would be `terraform@gitlab-<ENV>.iam.gserviceaccount.com`
    1. The new role would be `Cloud KMS CryptoKey Decryptor`
    1. Click `Save`
1. Encrypt our chef `validation.pem` file and upload it to our bootstrap bucket
   for the new project
    1. Download the validator private key from 1password
       * Search for `validator-gitlab`
       * Copy the `PRIVATE-KEY` to a file locally `validation.pem`
    1. Encrypt the file using our newly created key ring
       * `gcloud kms encrypt \
            --ciphertext-file=validation.enc \
            --plaintext-file=validation.pem \
            --key gitlab-<ENV>-boostrap-validation \
            --keyring gitlab-<ENV>-bootstrap \
            --location global`
      * Delete the `validation.pem` file
      * Upload the `validation.enc` to our bucket
        * `gsutil cp validation.enc
          gs://gitlab-<ENV>-chef-bootstrap/validation.enc`
1. You may now proceed to creating instances in your new project
    * The project will be in a directory named the same as `<ENV>` at this path:
      https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/tree/master/environments
    * You'll also want the necessary chef-roles to go along with this
      environment, which will be placed at this path:
      `https://ops.gitlab.net/gitlab-cookbooks/chef-repo/-/tree/master/roles`

## Future Work

* Some of the above will be removed with work to be completed here: https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/8165
