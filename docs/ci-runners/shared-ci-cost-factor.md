# Shared Runners Cost Factor

A new GitLab.com only feature of CI is the option to add a "cost factor" to
shared runners for public and/or private projects. This is a number by which any
minutes used will be multiplied and deducted from the user/groups allocated CI
minutes. For example, if we were to set the public cost factor to 2.0, all minutes would be multiplied by 2 and deducted from the customer's available minutes. `10 minutes * 2 cost = 20 minutes deducted`

Currently all shared runners have a factor of 0.0 for public projects and 1.0
for private projects, meaning there is no cost for public projects and a rate of
1 minute/minute for private runners.
