# How to upload a file to Google Cloud Storage from any system without a credentials configuration

This document describes how to use `gsutil signurl` and a couple of `curl` calls to upload files directly to GCS from gitaly nodes (or any other system).  From the official documentation:

> To construct a signed `URL` that allows anyone in possession of the `URL` to `POST` a resumable upload to the specified bucket for one day, creating an object of `Content-Type` [`application/tar+gzip`], run:

```bash
gsutil signurl -m RESUMABLE -d 24h -c application/tar+gzip <private-key-file> gs://bucket/<obj>
```

-- https://cloud.google.com/storage/docs/gsutil/commands/signurl

The documentation presumes that you have configured Google Cloud credentials so that you may use `gcloud` and `gsutil`.

The goals here are to avoid having to rely on such configuration on any other system, and to avoid having to alter permissions on another system in order to temporarily download a large file artifact to your local workstation, just to be able to then upload it to cloud storage.

## Key selection/creation

First step is to figure out which keys to use for the signed url.

The example from the documentation is:

```bash
gcloud iam service-accounts keys list --iam-account [SA-NAME]@[PROJECT-ID].iam.gserviceaccount.com
```

Where `SA-NAME` is the service account name, and `PROJECT-ID` is the string identifier for the project with which you intend to use for the destination Google Cloud Storage bucket.

In order to obtain these pieces of information, you must operate a few commands.  First, find the exact project identifier string for the project to which you require access for operations.

### Find a project

```bash
$ gcloud projects list --filter gitlab-internal | awk 'NR==2 {print $1}'
gitlab-internal-153318
```

### Project config

Update your local `gcloud` configuration to use this `gitlab-internal` project.

```bash
$ gcloud config set project gitlab-internal-153318
Updated property [core/project].
```

### Service account required

A service account key is required for the `gsutil signurl` command to work.

You may either create a brand new service account for this, or use an existing one.

```bash
$ gcloud iam service-accounts create gitlab-project-storage-internal --display-name "Gitlab Internal Project Storage"
```

If you have decided to create a new service account, please consider also deleting the account when the work which required its creation has completed.

```bash
$ gcloud iam service-accounts delete gitlab-project-storage-internal
```

It should go without saying, but please don't delete a service account that you yourself did not also create.

### Create a service account key

Create a service account key on an existing service account for use for this work.  I'm naming this file `gitlab-gcs-key-35864.json` so it includes the issue number that is tracking the work I am doing.

```bash
$ gcloud iam service-accounts keys create ~/gitlab-gcs-key-35864.json --iam-account gitlab-gcs@gitlab-internal-153318.iam.gserviceaccount.com
```

### Create a new bucket

Now, create a new bucket in GCS.

```bash
$ gsutil mb -l us-east1 gs://vsizov-test-git-repos-35864/
```

Or else use an existing one.

```bash
$ gsutil ls
```

### Set the bucket access control

The bucket access control list must be configured.

```bash
$ gsutil acl ch -u gitlab-gcs@gitlab-internal-153318.iam.gserviceaccount.com:WRITE gs://vsizov-test-git-repos-35864
```

### Create a signed url

Make sure that you know what the name of the file is which will be stored in the GCS bucket.

For example, a `~30 GB` gzipped git repository tarball, `7ea325136e6d19b8ae3561d28652a557dbfcba11da21bfd81ebb2ff19f844e62.tar.gz`.

Create a signed url that allows anyone in possession of the url to `POST` a resumable upload to the specified bucket for six hours, creating an object of `Content-Type: application/tar+gzip`:

```bash
$ gsutil signurl -m RESUMABLE -d 24h -r us-east1 -c application/tar+gzip ~/gitlab-gcs-key-35864.json gs://vsizov-test-git-repos-35864/7ea325136e6d19b8ae3561d28652a557dbfcba11da21bfd81ebb2ff19f844e62.tar.gz
URL HTTP Method Expiration  Signed URL
gs://vsizov-test-git-repos-35864/7ea325136e6d19b8ae3561d28652a557dbfcba11da21bfd81ebb2ff19f844e62.tar.gz    RESUMABLE   2020-01-30 18:38:20 https://storage.googleapis.com/vsizov-test-git-repos-35864/7ea325136e6d19b8ae3561d28652a557dbfcba11da21bfd81ebb2ff19f844e62.tar.gz?x-goog-signature=[redacted]&x-goog-algorithm=GOOG4-RSA-SHA256&x-goog-credential=gitlab-gcs%40gitlab-internal-153318.iam.gserviceaccount.com%2F20200130%2Fus-east1%2Fstorage%2Fgoog4_request&x-goog-date=20200130T183820Z&x-goog-expires=21600&x-goog-signedheaders=content-type%3Bhost%3Bx-goog-resumable
```

### Uploading a file

Operating the `POST` and subsequent `PUT` commands for `curl`.  Complete documentation here: https://cloud.google.com/storage/docs/access-control/signed-urls#signing-resumable

The following command yields a url in the `location` response header, to which the actual file data will be `PUT`:

```bash
$ export SIGNED_URL='https://storage.googleapis.com/vsizov-test-git-repos-35864/7ea325136e6d19b8ae3561d28652a557dbfcba11da21bfd81ebb2ff19f844e62.tar.gz?x-goog-signature=[redacted]&x-goog-algorithm=GOOG4-RSA-SHA256&x-goog-credential=gitlab-gcs%40gitlab-internal-153318.iam.gserviceaccount.com%2F20200130%2Fus-east1%2Fstorage%2Fgoog4_request&x-goog-date=20200130T183820Z&x-goog-expires=21600&x-goog-signedheaders=content-type%3Bhost%3Bx-goog-resumable'
$ export LOCATION_URL=`curl --silent --location --request POST "${SIGNED_URL}" --header 'Content-Type: application/tar+gzip' --header 'x-goog-resumable: start' --data '' --include | grep 'Location: ' | awk '{print $2}'`
```

```bash
$ echo "${LOCATION_URL}"
https://storage.googleapis.com/vsizov-test-git-repos-35864/7ea325136e6d19b8ae3561d28652a557dbfcba11da21bfd81ebb2ff19f844e62.tar.gz?x-goog-signature=[redacted]&x-goog-algorithm=GOOG4-RSA-SHA256&x-goog-credential=gitlab-gcs%40gitlab-internal-153318.iam.gserviceaccount.com%2F20200130%2Fus-east1%2Fstorage%2Fgoog4_request&x-goog-date=20200130T183820Z&x-goog-expires=21600&x-goog-signedheaders=content-type%3Bhost%3Bx-goog-resumable&upload_id=[redacted]
```

Now the file may be uploaded to Google Cloud Storage.

```bash
$ curl --verbose --request PUT "${LOCATION_URL}" --output /tmp/curl.log --upload-file 7ea325136e6d19b8ae3561d28652a557dbfcba11da21bfd81ebb2ff19f844e62.tar.gz
```
