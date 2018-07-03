# Gemnasium is down

## Case 1: the HTTP service doesn't respond (not error 500)

### Symptoms

- The Dependency Scanning jobs fail because they can't contact the Gemnasium API.
- https://deps.sec.gitlab.com/ doesn't respond or fails with an error.
 
### Pre-checks

Try connecting to https://deps.sec.gitlab.com/ , a page listing packages by technologies should display. If it doesn't 
then the service is down. 

### Resolution
 
- Navigate to the [GCP page for the Gemnasium web workload](https://console.cloud.google.com/kubernetes/statefulset/us-central1-b/production/default/web?project=gemnasium-production&tab=details&duration=PT1H&pod_summary_list_tablesize=20) 
- Its status shouldn't be "running".

If the status is not "running", the "Events" tab might list the cause of the failure.

In any case, restart the workload. To achieve this, you can force a rolling update:
- Navigate to the [Kubernetes production cluster](https://console.cloud.google.com/kubernetes/list?project=gemnasium-production).
- Click "connect" and then "run in cloud shell".
- Run the command it auto fills in.
- Relabel the web workload to trigger a rolling update and restart the pods:
```
kubectl patch statefulset web -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"`date +'%s'`\"}}}}}"
```
- The pods should restart immediately and the service should respond again on its HTTP(s) port in less than a minute.

### Post-checks
 
Browse https://deps.sec.gitlab.com/explore , the website should appear.

## Case 2 : the HTTP service returns a 5xx error (likely a database error)

### Symptoms

- The Dependency Scanning jobs fail because the Gemnasium service fails (error 500).
- https://deps.sec.gitlab.com/explore/packages/gem/browse fails to list any packages.
 
### Pre-checks

Try connecting to https://deps.sec.gitlab.com/explore/packages/gem/browse , a page listing Gem packages by technologies 
should display. If it doesn't then the service fails, most likely it can't contact its database server.

Check the application logs to be sure:
- Navigate to the [GCP page for the Gemnasium web workload](https://console.cloud.google.com/kubernetes/statefulset/us-central1-b/production/default/web?project=gemnasium-production&tab=details&duration=PT1H&pod_summary_list_tablesize=20) 
- Navigate to one of its pods.
- Navigate to the "Logs" tab, the application logs should reflect a problem with connecting to the database.

Check the database:
- Navigate to the [GCP page for the Gemnasium database service](https://console.cloud.google.com/sql/instances/db/overview?project=gemnasium-production&duration=PT1H)

### Resolution

If the database is stopped, fix the issue and restart it.

Restart the "web" workload if the service still doesn't work:
- Navigate to the [Kubernetes production cluster](https://console.cloud.google.com/kubernetes/list?project=gemnasium-production).
- Click "connect" and then "run in cloud shell".
- Run the command it auto fills in.
- Relabel the web workload to trigger a rolling update and restart the pods:
```
kubectl patch statefulset web -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"`date +'%s'`\"}}}}}"
```

### Post-checks
 
- Browse https://deps.sec.gitlab.com/explore/packages/gem/browse , Gem packages should be listed.
- Query the API:
```
curl -d '[{"type": "gem", "name": "nokogiri"},{"type": "gem", "name": "actionpack"}]' https://deps.sec.gitlab.com/api/advisories/q
```

Several screens of JSON data should be returned.
