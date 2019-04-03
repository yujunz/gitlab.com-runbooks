## CI/CD Constant Number of Long Running, Repeated Jobs
Alert Name: CICDNamespaceWithConstantNumberOfLongRunningRepeatedJobs

This alert does not directly indicate a failure of the CI/CD system to work, but is designed to look for abuse or unusual use of the system.

You can begin investigating the issue by looking up the namespace to see what projects to look through. Connect to the rails console and load the namespace: ```ns = Namespace.find(1234567)```. When you do this, you should see information about the namespace that can get you headed in the right direction.

It may also be necessary to block the user and stop their CI/CD processes from running. If there is any doubt, or it appears to be abuse, report it to the abuse team.
