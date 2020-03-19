## CI/CD Workhorse Queuing Slow
Alert Name: CICDWorkhorseQueuingUnderperformant

Requests from runner to gitlab go through workhorse. Usually these requests are handled in under one second. If they are taking longer, this alert will fire.

This slowdown can affect requesting new jobs, updating handled ones and artifact operations.
