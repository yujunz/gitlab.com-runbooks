# Sidekiq Queue Out of Control

When the filesystem or database has major issues, it is possible
for the sidekiq queues to grow out of control. If the queues don't appear
to be getting any better after resolving other issues, please follow
the resolution below.

## Resolution

For now, the fix is to restart all the sidekiq workers. This is 
not the ideal solution, but for now it is the best we have.

## References

https://gitlab.com/gitlab-com/infrastructure/issues/606
https://gitlab.com/gitlab-com/infrastructure/issues/584
