## CI/CD Too Many Archiving Trace Failures
Alert Name: CICDTooManyArchivingTraceFailures

Trace logs are archived to S3. When the trace archiver tries to put a trace into S3 and fails, the counter is increased. This doesn't always mean that data is lost. Each attempt to write the trace to S3 is tried up to 3 times.

It's possible this is caused by a stale file handle that needs to be cleaned up.
