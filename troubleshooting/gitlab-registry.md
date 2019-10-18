## Reason

GitLab Container Registry is not responding or returns not 200 OK statuses.

## Possible checks

1. Open https://registry.gitlab.com and if you are seeing empty page, not 4xx or 5xx error page, then things are generally functional, and you don't need to panic heavily.  However, continue looking for more subtle causes.
1. Validate running pods:
    * On the approriate Kubernetes Cluster run, `kubectl get pods -l
      app=registry -n gitlab`
1. In more subtle cases, we might have something only slightly-broken.  Check the registry logs in Kibana (index pattern: `pubsub-gke-inf-[gstg|gprd]*`), using filter: `json.logName: projects/[gitlab-production|gitlab-staging-1]/logs/registry` and browse for anything suspect.
   1. Adding this querye `json.logName:"projects/gitlab-production/logs/registry" AND json.jsonPayload.msg:"response completed with error" AND json.jsonPayload.err.message:"unknown error"` has been known to show problems that used to be visible by searching for `"invalid checksum digest format"`.  There shouldn't be any of those under normal circumstances; this is often caused by transient upload issues leaving empty or otherwise corrupt images (tag links empty, or pointing to non-existent layers).  C.f. https://gitlab.com/gitlab-com/gl-infra/production/issues/906.  In the GitLab UI, these images show up as some combination of an empty tag id, null bytes, 0 bytes, and typically 'Last Updated' is stuck at 'Just now'.  Deleting through the UI is not possible (HTTP 400 Bad Request seen in the dev console when trying).  See below for resolution.

## What to do?

1. Whenever a PagerDuty alert fires off for registry issues such as [5xx Error Rate on Docker Registry Load Balancers](https://gitlab.pagerduty.com/incidents/PFC3EAS), please:
    * Create an incident issue, note down the date, duration, and impact.  Also make note of whether or not Support was contacted in order to assist unblocking users.
    * Link to the issue for [The Container Registry needs improvements to error handling](https://gitlab.com/gitlab-org/gitlab/issues/32907).
    * Close the incident issue when the PagerDuty alert eventually resolves.
    * Based on such issues, the priority of the root cause issue(s) may be adjusted based on a data-based analysis of its severity.

1. Determine the state of the Pods
    * If they are running, find out why they are tossing errors
      * Check the status of GCS - https://status.cloud.google.com/
      * Look at logs described above
    * If we have a low amount of pods, less than baseline (roughly 20) validate
      we are receiving traffic at the haproxy layer
    * If we have MANY pods, more than baseline, or at the max of the HPA, that
      may signal a performance and/or a network issue that must be investigated
      further
    * If the Pods are in a CrashLoop, look in the logs to find out why
    * If the Pods are stuck in state `Init...`; perform a `describe` command and
      look at the `Events` associated with that Pod to guide next steps: `kubectl
      describe pod <podname>`
    * Validate the Service Endpoints in Kubernetes
      * `kubectl describe service gitlab-registry -n gitlab`
      * Validate the `LoadBalancer Ingress` IP matches that for which haproxy
        knows as the `gke-backend`
    * Validate the Service has our Pod Endpoints
      * `kubectl describe endpoints gitlab-registry -n gitlab`
      * There should be 1 address for each pod that is in state `Running` listed
        in `Addresses`
      * If there are none, validate we have running Pods

1. Check the state of haproxy load balancers
    * Ensure the Load Balancers are serving traffic
      * Each server should be listed in an OK state in the GCP load balancers:
        * `gprd-gcp-tcp-lb-registry-http`
        * `gprd-gcp-tcp-lb-registry-https`
    * Ensure haproxy is healthy
      * Validate the service is running
      * Validate the `gke-registry` backend is healthy

### Broken images - empty/null/just now, "invalid checksum digest format", "unknown error"
From the error logs, you should see a URI in the form `/v2/<group>/<nestedgroup>/<project>/<imagename>/manifests/<tag>`.

You can also check the haproxy logs on the frontend load balancers `fe-registry-0[1|2]-lb-gprd.c.gitlab-production.internal` for the paths which are returning 5xx errors, sorted by frequency.

```
$ sudo su -
# cd /var/log
# grep ' 500 ' haproxy.log <(zcat haproxy.log.1.gz)|sed 's/.*} "GET \(.*\) HTTP.*$/\1/'|sort|uniq -c|sort -nr|head -5
    174 /v2/someuser/really-awesome-project/manifests/even-awesomer-build
    141 /v2/otheruser/backend/backup/manifests/latest
     80 /v2/popular-opensource-project/app-name/other-qualifier/manifests/latest
     67 /v2/anotheruser/dev/image/manifests/ecec8e83437ef4bf5a161eb47cce4cdfe285b87e
     40 /v2/fakeorg/fakeproject/fakeimage/manifests/8feaca0e4ac8710fc8e966fcaaf038f656db4571
```

Once the failing image is identified, there are two ways to fix it:
1. Re-push an image to the tag; this seems to just overwrite and clears the problem.  Often can be done by simply re-running the CI job, if such exists
1. Delete the tag entirely, from the underlying object storage.

We should usually ask the customer nicely to try the first option themselves; contact support and get them to reach out.  However, the image is fundamentally broken, and won't magically fix itself, so retain the option to Just Do It if circumstances feel right, e.g. long delay in getting a response, or the issue is super widespread and we're drowning in fail logs.  To do the deletion:

Goto https://console.cloud.google.com/storage/browser in the gitlab-production project, and navigate into the registry bucket (gitlab-prd-registry), then down into `docker/registry/v2/repositories/`.  From there, follow the (nested) group names, to the image name, then into `\_manifests/tags`.  There should be a folder with the tag from the original error log.  Optionally have a poke in that folder (if you're interested in exact failure modes), but then just delete the tag folder.

#### Failure modes
If you're investigating further, there's at least two cases seen so far:
1. Inside this folder there's some more folders, ending in link files, the contents of which reference non-existent layers in the _layers folder (sibling of _manifests)
1. Inside this folder, in current/link the link file is *empty* (which correlates more directly with the UI experience often seen)

It may be worth noting which case we're seeing, and if you see other failure modes, note them down too.  We should eventually get to the bottom of the source of these corrupt states, and fix them there.

#### Repairing 500 errors

There [is a script](../scripts/registry_scanner.rb) that will help identify which file is broken. To run it:

```sh
./registry_scanner.rb /v2/someuser/really-awesome-project/manifests/even-awesomer-build
```

The output will show something like this:

```
Checking tag even-awesomer-build...
Checking revision 14dccc1ea5804e70e77bc62d7e96ded4032c16fa1d32f94f96bb909f3408dadc
Checking blob 14dccc1ea5804e70e77bc62d7e96ded4032c16fa1d32f94f96bb909f3408dadc...
0-byte file found: gs://gitlab-gprd-registry/docker/registry/v2/blobs/sha256/14/14dccc1ea5804e70e77bc62d7e96ded4032c16fa1d32f94f96bb909f3408dadc/data

To remove these file(s), you may want to run:
================================================
gsutil rm gs://gitlab-gprd-registry/docker/registry/v2/blobs/sha256/14/14dccc1ea5804e70e77bc62d7e96ded4032c16fa1d32f94f96bb909f3408dadc/data
gsutil rm -r gs://gitlab-gprd-registry/docker/registry/v2/repositories/someuser/really-awesome-project/_manifests/revisions/sha256/14dccc1ea5804e70e77bc62d7e96ded4032c16fa1d32f94f96bb909f3408dadc
gsutil rm -r gs://gitlab-gprd-registry/docker/registry/v2/repositories/someuser/really-awesome-project/_manifests/tags/even-awesomer-build
================================================
```
