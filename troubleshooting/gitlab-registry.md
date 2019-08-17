## Reason

GitLab registry is not responding or returns not 200 OK statuses.

## Possible checks

1. Open https://registry.gitlab.com and if you are seeing empty page, not 4xx or 5xx error page, then things are generally functional, and you don't need to panic heavily.  However, continue looking for more subtle causes.
1. Also you can check by running `knife ssh role:gprd-base-fe-registry 'sudo gitlab-ctl status registry'`. If you are seeing messages like `worker15.cluster.gitlab.com run: registry: (pid 1091) 2107486s; run: log: (pid 1085) 2107486s`, then also again things are generally functional.  If registry is not working you will be seeing services in `down` state, and should restart (see below).
1. In more subtle cases, we might have something only slightly-broken.  Check the registry logs in Kibana (index pattern: `pubsub-registry-inf-[gstg/gprd]*`), look for suspicious stuff.
   1. One useful query is `"invalid checksum digest format"`  There shouldn't be any of those under normal circumstances; in at least one situation, this was caused by transient upload issues leaving empty images (tag links empty, or pointing to non-existent layers).  C.f. https://gitlab.com/gitlab-com/gl-infra/production/issues/906.  In the GitLab UI, these images show up as some combination of an empty tag id, null bytes, 0 bytes, and typically 'Last Updated' is stuck at 'Just now'.  Deleting through the UI is not possible (HTTP 400 Bad Request seen in the dev console when trying).  See below for resolution.
   1. Other possible queries include for `json.message:"http.response.status\":500"`.  We should really decompose the json output into structured fields, so we can search on e.g. http.response.status more directly, and do visualisations, but this query will do for now.

## What to do?

1. Try restart service with the command `sudo gitlab-ctl restart registry` if it is down.

### Broken images - empty/null/just now, "invalid checksum digest format"
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
