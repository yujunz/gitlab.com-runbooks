# GitLab Hosted CodeSandbox

In
[infrastructure#6709](https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/6709),
we were asked to create a bucket and CDN for a GitLab hosted CodeSandbox.
[CodeSandbox](https://codesandbox.io/) is JavaScript that enables live preview
updates on our web IDE using JavaScript for client-side rendering. We intend to
enable this for GitLab.com with release 12.1 and will be available to
self-hosted customers using a [configuration
option](https://docs.gitlab.com/ee/user/project/web_ide/index.html#enabling-client-side-evaluation)
in the admin panel.

## Set Up

We have created the `gitlab-gprd-codesandbox` bucket in the `gitlab-production`
project on GCP. Because the files there are public and will be consumed by
everyone, the bucket is set to public. The CDN frontend domain is
https://sandbox.gitlab-static.net/ and is set up in Fastly with TLS under the
name `sandbox.gitlab-static.net`.

It was decided that none of the above would be in terraform as it did not fit
into our current model of terraform and will likely never be touched. 

## Deployment (tentative)

The method of deployment to this bucket is still being researched and decided
upon, however the initial plan is to create a simple CI pipeline that does the
following:

1. `npm install smooshpack`
1. Copy `node_modules/smooshpack/sandpack` to the bucket.
