Rough notes on TLS certs for \*.gitlab-review.app

Actual repos are changing, but it looks like the new single master repo (`gitlab`, was `gitlab-ee`) will be using \*.gitlab-review.app for it's GKE k8s hosted review apps.

The cert for this is stored in a K8S secret.  To replace this when it expires:
1. Assume sslmate has autorenewed this
1. sslmate download '\*.gitlab-review.app'
1. Assume the key has remained the same; it's in the secret, and can be left
1. `cat '\*.gitlab-review.app.chained.crt' |base64|tr -d '\n'`
1.   * Save this output somewhere handy, briefly
1. `gcloud container clusters get-credentials review-apps-ee --zone us-central1-b --project gitlab-review-apps`
1.   * Assumes you have gcloud and kubectl generally installed and working; this adds a cluster config to your .kube/config file, and sets it to be the current context
1. Save the existing secret:  `kubectl get secret tls-cert --namespace review-apps-ee -o yaml > old-gitlab-review-app.secret
1. `kubectl edit secret tls-cert --namespace review-apps-ee`
1. Carefully replace the existing tls.crt value with the base64 encoded cert you output above.  Leave tls.key alone.  Save, quit

This will automatically apply (within a few seconds last time).
