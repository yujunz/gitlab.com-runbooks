## CI/CD Constant Number of Long Running, Repeated Jobs
Alert Name: CICDNamespaceWithConstantNumberOfLongRunningRepeatedJobs

This alert does not directly indicate a failure of the CI/CD system to work, but is designed to look for abuse or unusual use of the system.

You can begin investigating the issue by looking up the namespace to see what projects to look through. Connect to the rails console and load the namespace: ```ns = Namespace.find(1234567)```. When you do this, you should see information about the namespace that can get you headed in the right direction.

It may also be necessary to block the user and stop their CI/CD processes from running. If there is any doubt, or it appears to be abuse, report it to the abuse team.

### Large numbers of pending jobs
Some things to note about pending jobs and abuse or mis-use of CI:
* With Shared Runners disabled for the project they all became stuck, and will be removed by StuckCiJobsWorker after next 24 hours. This may be the best way to get rid of lots of pending jobs.
* If you do need to remove a large number of pending jobs, consider a simple bash script such as the one below.

```bash
PRIVATE_TOKEN=XXX
GITLAB_URL=gitlab.com
PROJECT_FULL_NAME=[user|group]%2f[project name]

CURL_OUT=$(curl -f -s --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "https://$GITLAB_URL/api/v4/projects/$PROJECT_FULL_NAME/pipelines?status=pending")
while [ $CURL_OUT != "[]" ]; do
  echo $CURL_OUT | jq -r '.[].id' | \
  awk -v GITLAB_URL=$GITLAB_URL \
    -v PROJECT_FULL_NAME=$PROJECT_FULL_NAME \
    '{print "https://"GITLAB_URL"/api/v4/projects/"PROJECT_FULL_NAME"/pipelines/"$1"/cancel"}' | \
  while read PIPE_CANCEL_URL; do
    curl -s --request POST --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" $PIPE_CANCEL_URL | jq -r
  done
  CURL_OUT=$(curl -f -s --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "https://$GITLAB_URL/api/v4/projects/$PROJECT_FULL_NAME/pipelines?status=pending")
  echo "Pausing 10 seconds."
  sleep 10
done
echo "No more jobs found."

```
