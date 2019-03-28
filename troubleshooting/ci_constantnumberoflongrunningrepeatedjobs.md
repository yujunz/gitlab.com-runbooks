## CI/CD Constant Number of Long Running, Repeated Jobs
Alert: CICDNamespaceWithConstantNumberOfLongRunningRepeatedJobs

Sometimes there are CI jobs that have the intent of using our machine time to run a process that is not part of a normal CI/CD process. Sometimes, the automated machines built will be used to run applications like a bitcoin miner, or some similar process.

This alert does not directly indicate a failure of the CI/CD system to work, but is designed to look for abuse or unusual use of the system.

Use the namespace information provided in the alert to find out 
