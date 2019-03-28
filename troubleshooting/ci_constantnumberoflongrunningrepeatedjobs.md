## CI/CD Constant Number of Long Running, Repeated Jobs
Alert Name: CICDNamespaceWithConstantNumberOfLongRunningRepeatedJobs

Sometimes there are CI jobs that have the intent of using our machine time to run a process that is not part of a normal CI/CD process. Sometimes, the automated machines built will be used to run applications like a bitcoin miner, or some similar process.

This alert does not directly indicate a failure of the CI/CD system to work, but is designed to look for abuse or unusual use of the system.

You can begin investigating the issue by looking up the namespace to see what projects to look through. Connect to the rails console and load the namespace: ```ns = Namespace.find(1234567)```. When you do this, you should see information about the namespace that can get you headed in the right direction.

If there is any doubt, or it appears to be abuse, report it to the abuse team.
