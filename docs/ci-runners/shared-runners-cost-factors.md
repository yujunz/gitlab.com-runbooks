# Shared Runners Cost Factors

> Available for GitLab.com Admins only

Cost Factor is a multiplier for every CI minute being counted towards the Usage Quota.  
`Public` Cost Factor is applied to `public` projects jobs, `Private` Cost Factor is applied to `private` and `internal` projects jobs.

For example, if `Public` Cost Factor of the Runner is set to `0.0`, it would NOT count the time spent executing jobs for `public` projects towards the Usage Quota at all.  
Similarly, if `Private` Cost Factor of the Runner is set to `1.0`, it would count every minute spent executing jobs for `private`/`internal` projects without applying any additional multiplier to the time spent.  

Setting a value, different from `0.0` and `1.0`, could be used to adjust the "price" of a particular runner.  
For instance, setting the multiplier to `2.0` will make each physical minute to consume 2 minutes from the quota.  
Setting the multiplier to `0.5` will make each physical minute to consume only 30 seconds from the quota.  

It is possible to adjust Cost Factors for the particular runner:  

1. Navigate to **Admin > Runners**
1. Find the Runner you wish to update
1. Click edit on the Runner
1. Edit Cost Factor fields and save the changes

Cost Factors are stored in the `ci_runners` DB table, in `public_projects_minutes_cost_factor` and `private_projects_minutes_cost_factor` fields.  

Default Cost Factors values are `public_projects_minutes_cost_factor=0.0` and `private_projects_minutes_cost_factor=1.0`.
