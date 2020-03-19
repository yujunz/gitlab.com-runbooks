# Camoproxy troubleshooting

## Blackbox alerting

The core alerts are simple, using the blackbox exporter, and are only checking that camoproxy is responding with an HTTP 200 to the /status URL. 

If this is not working, then you're probably looking at all instances of camoproxy being down and the HTTPS GCP load balancer is returning an error code.

Quick recap of what *should* be the correct running path:

GCP HTTPS LB with a public IP, holder of the SSL certificate (terminates SSL).  This is user-content.gitlab-static.net.
The LB talks/balances to haproxy on port 80 on the camoproxy nodes; haproxy is just doing URL blacklisting because it's simple doing this, fast, and we have equivalent tooling for IP blacklisting elsewhere. 
Each haproxy has a single backend that is the local (to the same node) camoproxy instance on port 8080.

The healthcheck URL the LB uses is /status, and haproxy passes this through to camoproxy, making it a simple end-to-end "is camoproxy alive, accepting HTTP, and in theory able to process other requests" sort of check.  

## Logging 

### Raw

In elasticsearch/kibana, check out the pubsub-camoproxy-inf-gprd index.  As a quick guide, the field 'json.camoproxy\_message' describes the basic message, and then each type of message has one of json.camoproxy\_{req,resp,url} depending on the message.  

To see URLs passing through the proxy, search for `json.camoproxy_message:"signed client url"` and look at the json.camoproxy\_url field.

The "built outgoing request" message shows the HTTP request we're sending to the external service, and the "response from upstream" message shows the full headers being returned from that call.  The "response to client" message shows the HTTP response (mostly headers) being sent back to the original client.

NB: json.camoproxy_level is almost always 'D' for debug; there's next to no interesting logging at below debug level.

### Metrics from logs

Using mtail, we scrape the logs and count certain errors.  At this writing there is no alerting on these values as we can reasonably expect a small number of them, particularly timeouts, and we DO NOT CARE that something on the internet was a bit slow.  It would have been slow if we weren't involved in proxying it, and we can't fix it.  We *might* look at some sort of apdex scoring later, but this is a small and not particularly critical service and I'm wary of adding load to on-call for it being twitchy.

## Manual testing

If you need to generate a URL that you can pass through camoproxy to verify its behavior:
1. ssh to one of the camoproxy nodes
1. KEY=$(grep 'GOCAMO_HMAC=' /etc/sv/camoproxy/run|cut -d= -f2|tr -d '"')
1. URL=https://example.com/path/to/image.jpg
1. echo https://user-content.gitlab-static.net$(/opt/camoproxy/bin/url-tool --key $KEY encode $URL)

(NB: staging is at user-content.staging.gitlab-static.net; substitute the domain necessary, as the HMAC keys are not the same across both environments)

Alternatively, you can grab the camoproxy binaries from https://github.com/cactus/go-camo/releases/ to your laptop, and get the key value the same way or from the GKMS vault (`/path/to/chef-repo/bin/gkms-vault-show camoproxy gstg`)

## Graphs

It's unknown how useful these will be, but if it's alerting, maybe check to see if throughput is suddenly spiking or otherwise behaving badly:

<https://dashboards.gitlab.net/d/general-camoproxy/general-camoproxy>

## SSL certificate

The certificate is held by the GCP HTTPS Load balancer, not any of our layers.  It can be managed with the gcloud CLI, specifically the 'compute ssl-certificate' sub-commands.  The expected name of the cert can be verified in the camoproxy_cert_link variable in terraform, but should be the domain name with dots replaced by hyphens.  For example, uploading the staging certificate for the first time (having purchased/downloaded it with sslmate) was done with this:
`gcloud --project gitlab-staging-1 compute ssl-certificates create user-content-staging-gitlab-static-net  --certificate=user-content.staging.gitlab-static.net.chained.crt --private-key=user-content.staging.gitlab-static.net.key`

Updating is not tested at this time, and may require some careful work (perhaps changing to a temporary new certificate for the duration).
