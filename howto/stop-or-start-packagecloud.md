# PackageCloud [SCRAM](https://en.wikipedia.org/wiki/Scram) Button

In the event that a malicious or compromised package is deployed
to our package repo, we must stop PackageCloud immediately
to prevent users from downloading the compromised package.

This can be done via Marvin, our friendly GitLab Cog bot.

If you have access to Marvin, you can call this by simply typing 
the following into Slack:

```
!chef-job-start stop-packagecloud
```

Once we have resolved the issue or compromised package, we can 
restart PackageCloud in a similar way.

```
!chef-job-start start-packagecloud
```
